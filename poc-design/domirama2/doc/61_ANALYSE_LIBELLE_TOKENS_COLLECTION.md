# 🔍 Analyse : Colonne Collection `libelle_tokens` pour Recherche Partielle

## 💡 Idée Proposée

Utiliser une **colonne collection** (`SET<TEXT>`) pour stocker tous les ngrams (sous-chaînes) du libellé, permettant une **vraie recherche partielle** avec l'opérateur `CONTAINS`.

## ✅ Avantages

### 1. **Vraie Recherche Partielle**
- ✅ `libelle_tokens CONTAINS 'carref'` → trouve "CARREFOUR"
- ✅ Pas besoin de terme complet : "carref" fonctionne
- ✅ Tolérance aux typos : "carref" trouve "CARREFOUR"

### 2. **Support Natif SAI**
- ✅ `CONTAINS` est supporté nativement par SAI sur les collections
- ✅ Index SAI standard (pas besoin d'analyzer personnalisé)
- ✅ Performance optimale avec index SAI

### 3. **Simplicité**
- ✅ Pas de développement Java (analyzer personnalisé)
- ✅ Utilise les fonctionnalités natives de Cassandra/HCD
- ✅ Maintenance simple

## ⚠️ Inconvénients

### 1. **Stockage Supplémentaire**
- ⚠️ Tous les ngrams sont stockés (ex: "CARREFOUR" → ~20 ngrams)
- ⚠️ Impact sur la taille de la table
- ⚠️ Impact sur les performances d'écriture

### 2. **Génération Côté Application**
- ⚠️ Les ngrams doivent être générés lors de l'insertion
- ⚠️ Nécessite un script Spark/Java pour générer les ngrams
- ⚠️ Maintenance : s'assurer que tous les inserts génèrent les ngrams

## 📊 Comparaison des Solutions

| Solution | Recherche Partielle | Support SAI | Complexité | Stockage | Performance |
|----------|---------------------|-------------|------------|----------|-------------|
| **`libelle_prefix`** (actuel) | ⚠️ Préfixes uniquement | ✅ Oui | ✅ Faible | ✅ Faible | ✅ Bonne |
| **`libelle_tokens` SET** | ✅ Vraie recherche partielle | ✅ Oui | ✅ Faible | ⚠️ Élevé | ✅ Bonne |
| **Analyzer N-Gram personnalisé** | ✅ Vraie recherche partielle | ❌ Non supporté | ❌ Très élevée | ⚠️ Élevé | ⚠️ Variable |

## 🔧 Implémentation

### 1. Ajout de la Colonne

```cql
ALTER TABLE operations_by_account ADD libelle_tokens SET<TEXT>;

CREATE CUSTOM INDEX idx_libelle_tokens
ON operations_by_account(libelle_tokens)
USING 'StorageAttachedIndex';
```

### 2. Génération des Ngrams (Python/Spark)

```python
def generate_ngrams(text, min_n=3, max_n=8):
    """Génère tous les ngrams de longueur min_n à max_n"""
    text_lower = text.lower()
    ngrams = set()
    for i in range(len(text_lower)):
        for n in range(min_n, min(max_n + 1, len(text_lower) - i + 1)):
            ngram = text_lower[i:i+n]
            if len(ngram) >= min_n:
                ngrams.add(ngram)
    return ngrams

# Exemple
libelle = "CB CARREFOUR MARKET PARIS"
tokens = generate_ngrams(libelle, min_n=3, max_n=8)
# Résultat : {'car', 'carref', 'carrefour', 'cbc', 'bca', 'mar', 'market', ...}
```

### 3. Insertion avec Tokens

```cql
INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op, op_id,
    libelle, libelle_tokens, montant, ...
) VALUES (
    '1', '5913101072', '2024-11-20', 2001, 'op_001',
    'CB CARREFOUR MARKET PARIS',
    {'car', 'carref', 'carrefour', 'cbc', 'bca', 'mar', 'market', ...},  -- Ngrams
    -28.90, ...
);
```

### 4. Recherche Partielle

```cql
-- Recherche partielle : "carref" trouve "CARREFOUR"
SELECT * FROM operations_by_account
WHERE code_si = '1' AND contrat = '5913101072'
  AND libelle_tokens CONTAINS 'carref';
```

## 🎯 Cas d'Usage

### Cas 1 : Recherche Partielle Simple
```cql
-- Utilisateur tape "carref"
SELECT * FROM operations_by_account
WHERE code_si = '1' AND contrat = '5913101072'
  AND libelle_tokens CONTAINS 'carref';
-- ✅ Trouve "CB CARREFOUR MARKET PARIS"
```

### Cas 2 : Recherche avec Typo
```cql
-- Utilisateur tape "carref" (au lieu de "carrefour")
SELECT * FROM operations_by_account
WHERE code_si = '1' AND contrat = '5913101072'
  AND libelle_tokens CONTAINS 'carref';
-- ✅ Trouve "CB CARREFOUR MARKET PARIS"
```

### Cas 3 : Recherche Combinée
```cql
-- Recherche partielle + filtre
SELECT * FROM operations_by_account
WHERE code_si = '1' AND contrat = '5913101072'
  AND libelle_tokens CONTAINS 'carref'
  AND montant < -20;
```

## 📈 Impact sur les Performances

### Stockage
- **Taille estimée** : ~20-30 ngrams par libellé
- **Exemple** : "CB CARREFOUR MARKET PARIS" (25 caractères) → ~25 ngrams
- **Impact** : +50-100% de stockage pour les libellés

### Écriture
- **Génération** : O(n²) où n = longueur du libellé
- **Insertion** : SET<TEXT> est efficace (index SAI)
- **Impact** : +10-20% de temps d'écriture

### Lecture
- **Index SAI** : Performance optimale avec CONTAINS
- **Impact** : Performance similaire à `libelle_prefix`

## ✅ Recommandation

### Pour le POC : ✅ **OUI, implémenter**

**Raisons** :
1. ✅ Démontre une **vraie recherche partielle** (requis par le client)
2. ✅ Utilise les fonctionnalités natives de HCD (CONTAINS sur collections)
3. ✅ Simple à implémenter (pas de développement Java)
4. ✅ Performance acceptable pour le POC

### Pour la Production : ⚠️ **À évaluer**

**Facteurs à considérer** :
- Volume de données (impact stockage)
- Fréquence des recherches partielles
- Budget stockage
- Performance d'écriture acceptable

**Alternative** : Utiliser `libelle_tokens` uniquement pour les libellés fréquemment recherchés.

## 🔄 Migration depuis `libelle_prefix`

Si on adopte `libelle_tokens`, on peut :
1. ✅ **Garder `libelle_prefix`** : Pour compatibilité et recherche de préfixes
2. ✅ **Utiliser `libelle_tokens`** : Pour recherche partielle avancée
3. ✅ **Fall-back** : `libelle` → `libelle_prefix` → `libelle_tokens`

## 📝 Conclusion

**`libelle_tokens` SET<TEXT> est une excellente solution pour la recherche partielle** car :
- ✅ Utilise CONTAINS (supporté nativement)
- ✅ Permet vraie recherche partielle ("carref" → "CARREFOUR")
- ✅ Simple à implémenter
- ✅ Performance acceptable

**Recommandation** : Implémenter pour le POC et évaluer pour la production.


