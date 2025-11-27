# 🔍 Pourquoi ne peut-on pas mettre un index N-Gram sur `libelle` ?

## ❌ Limitation SAI : Un seul index par colonne

**Réponse courte** : **NON**, il n'est pas possible de créer un index N-Gram séparé sur `libelle` car **SAI ne permet qu'un seul index par colonne**.

### Preuve technique

Lorsqu'on tente de créer un deuxième index SAI sur `libelle`, on obtient l'erreur suivante :

```cql
CREATE CUSTOM INDEX idx_libelle_ngram_test 
ON operations_by_account(libelle) 
USING 'StorageAttachedIndex' 
WITH OPTIONS = {...};

-- Erreur :
-- InvalidRequest: Error from server: code=2200 [Invalid query] 
-- message="Cannot create duplicate storage-attached index on column: libelle"
```

### Index existant

Il existe déjà un index sur `libelle` :

```cql
CREATE CUSTOM INDEX idx_libelle_fulltext_advanced
ON operations_by_account(libelle)
USING 'StorageAttachedIndex'
WITH OPTIONS = {
  'index_analyzer': '{
    "tokenizer": {"name": "standard"},
    "filters": [
      {"name": "lowercase"},
      {"name": "asciiFolding"},
      {"name": "frenchLightStem"}
    ]
  }'
};
```

Cet index fournit :
- ✅ Recherche full-text avec stemming français
- ✅ Gestion des accents (asciifolding)
- ✅ Recherche insensible à la casse
- ❌ **PAS de recherche partielle (N-Gram)**

---

## 🔄 Alternatives possibles

### 1. **Ajouter un filtre N-Gram à l'index existant** ⚠️

**Théoriquement possible** : On pourrait modifier l'index existant pour inclure un filtre N-Gram.

**Problèmes** :
- ❌ **SAI ne supporte pas nativement les filtres N-Gram** dans les analyzers Lucene standard
- ❌ Nécessiterait un **analyzer personnalisé en Java** (développement complexe)
- ❌ **Impact sur les performances** : L'index deviendrait beaucoup plus volumineux (tous les N-grammes de tous les libellés)
- ❌ **Impact sur les performances d'écriture** : Chaque insertion devrait générer tous les N-grammes

**Exemple théorique** (non supporté nativement) :
```cql
-- ❌ Ceci n'est PAS supporté par SAI
WITH OPTIONS = {
  'index_analyzer': '{
    "tokenizer": {"name": "standard"},
    "filters": [
      {"name": "lowercase"},
      {"name": "asciiFolding"},
      {"name": "frenchLightStem"},
      {"name": "ngram", "params": {"min": 3, "max": 5}}  -- ❌ Non supporté
    ]
  }'
};
```

### 2. **Colonne dérivée `libelle_prefix`** ✅ (Solution actuelle)

**Solution implémentée** : Création d'une colonne dérivée `libelle_prefix` avec un index séparé.

**Avantages** :
- ✅ **Simple à implémenter** : Pas besoin d'analyzer personnalisé
- ✅ **Performance contrôlée** : Seuls les préfixes sont indexés (pas tous les N-grammes)
- ✅ **Flexibilité** : On peut choisir la longueur du préfixe selon les besoins

**Inconvénients** :
- ⚠️ **Pas un vrai N-Gram** : Ne génère que les préfixes, pas toutes les sous-chaînes
- ⚠️ **Maintenance** : Il faut remplir `libelle_prefix` lors de l'insertion (via Spark/application)

**Exemple d'utilisation** :
```cql
-- Recherche partielle via libelle_prefix
SELECT * FROM operations_by_account
WHERE code_si = '1' 
  AND contrat = '5913101072'
  AND libelle_prefix : 'carref'  -- Trouve "CARREFOUR"
LIMIT 5;
```

### 3. **Créer un analyzer personnalisé en Java** 🔧

**Théoriquement possible** : Développer un analyzer Lucene personnalisé qui génère des N-grammes.

**Problèmes** :
- ❌ **Complexité élevée** : Nécessite développement Java, compilation, déploiement
- ❌ **Maintenance** : Code personnalisé à maintenir
- ❌ **Performance** : Impact significatif sur la taille de l'index et les performances d'écriture
- ❌ **Non recommandé** : DataStax ne recommande pas cette approche pour la production

---

## 📊 Comparaison des solutions

| Solution | Complexité | Performance | Flexibilité | Recommandation |
|----------|------------|-------------|------------|----------------|
| **N-Gram dans index existant** | ⚠️ Élevée | ❌ Faible | ⚠️ Limitée | ❌ Non recommandé |
| **Colonne dérivée `libelle_prefix`** | ✅ Faible | ✅ Bonne | ✅ Flexible | ✅ **Recommandé** |
| **Analyzer personnalisé Java** | ❌ Très élevée | ⚠️ Variable | ✅ Flexible | ❌ Non recommandé |

---

## ✅ Recommandation

**Utiliser la colonne dérivée `libelle_prefix`** (solution actuelle) car :

1. ✅ **Simple** : Pas de développement complexe
2. ✅ **Performant** : Index plus léger que les N-grammes complets
3. ✅ **Suffisant** : Les préfixes couvrent la plupart des cas d'usage (recherche partielle, typos)
4. ✅ **Maintenable** : Solution standard, pas de code personnalisé

### Amélioration possible

Si besoin de recherche partielle plus avancée, on peut :
- Créer plusieurs colonnes dérivées (`libelle_prefix_3`, `libelle_prefix_5`, etc.)
- Utiliser la recherche vectorielle (ByteT5) pour la tolérance aux typos (déjà implémentée)
- Combiner recherche full-text + recherche vectorielle (hybrid search, déjà implémentée)

---

## 📝 Conclusion

**Pourquoi pas de N-Gram sur `libelle` ?**

1. ❌ **Limitation SAI** : Un seul index par colonne
2. ❌ **Index existant** : `idx_libelle_fulltext_advanced` déjà présent
3. ❌ **N-Gram non supporté nativement** : Nécessiterait un analyzer personnalisé
4. ⚠️ **Impact performance** : Index beaucoup plus volumineux

**Solution recommandée** : ✅ Colonne dérivée `libelle_prefix` (déjà implémentée)


