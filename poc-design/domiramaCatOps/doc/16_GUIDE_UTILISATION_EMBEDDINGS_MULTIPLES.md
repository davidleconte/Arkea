# 📖 Guide d'Utilisation : Embeddings Multiples

**Date** : 2025-11-30  
**Dernière mise à jour** : 2025-01-XX  
**Version** : 1.0  
**Objectif** : Guide pratique pour utiliser les embeddings multiples (ByteT5 + e5-large)

---

## 🔗 Liens vers les Scripts

### Scripts de Configuration

- [`17_add_e5_embedding_column.sh`](../scripts/17_add_e5_embedding_column.sh) - Ajouter la colonne e5-large et créer l'index
- [`16_generate_relevant_test_data.sh`](../scripts/16_generate_relevant_test_data.sh) - Générer des données de test pertinentes
- [`18_generate_embeddings_e5_auto.sh`](../scripts/18_generate_embeddings_e5_auto.sh) - Générer les embeddings e5-large
- [`19_test_embeddings_comparison.sh`](../scripts/19_test_embeddings_comparison.sh) - Comparer ByteT5 vs e5-large

### Scripts de Test

- [`16_test_fuzzy_search.sh`](../scripts/16_test_fuzzy_search.sh) - Tests de recherche fuzzy avec ByteT5
- [`18_test_hybrid_search.sh`](../scripts/18_test_hybrid_search.sh) - Tests de recherche hybride (full-text + vector)

### Documentation Associée

- [16_RECOMMANDATION_MODELES_EMBEDDINGS.md](16_RECOMMANDATION_MODELES_EMBEDDINGS.md) - Recommandations sur les modèles d'embeddings
- [16_IMPLEMENTATION_MODELE_FACTURATION.md](16_IMPLEMENTATION_MODELE_FACTURATION.md) - Implémentation du modèle de facturation
- [demonstrations/16_COMPARAISON_BYTET5_E5_DEMONSTRATION.md](demonstrations/16_COMPARAISON_BYTET5_E5_DEMONSTRATION.md) - Démonstration de comparaison ByteT5 vs e5-large
- [demonstrations/16_COMPARAISON_3_MODELES_DEMONSTRATION.md](demonstrations/16_COMPARAISON_3_MODELES_DEMONSTRATION.md) - Démonstration de comparaison des 3 modèles

---

## 🚀 Démarrage Rapide

### 1. Installation des Dépendances

```bash
# Dépendances de base (déjà installées normalement)
pip install transformers torch cassandra-driver

# Pour e5-large (nouveau)
pip install sentence-transformers
```

### 2. Configuration du Schéma

```bash
# Ajouter la colonne e5-large et créer l'index
./scripts/17_add_e5_embedding_column.sh
```

**Résultat attendu** :

- ✅ Colonne `libelle_embedding_e5` créée
- ✅ Index `idx_libelle_embedding_e5_vector` créé
- ✅ Index `idx_meta_device` supprimé (slot libéré)

### 3. Génération des Données de Test

```bash
# Générer des opérations avec libellés pertinents
./scripts/16_generate_relevant_test_data.sh
```

**Résultat attendu** :

- ✅ 80 opérations avec libellés pertinents
- ✅ Couverture de toutes les requêtes de test

### 4. Génération des Embeddings e5-large

```bash
# Générer les embeddings (installe sentence-transformers si nécessaire)
./scripts/18_generate_embeddings_e5_auto.sh
```

**Résultat attendu** :

- ✅ Embeddings e5-large générés pour toutes les opérations
- ✅ Colonne `libelle_embedding_e5` remplie

### 5. Comparaison des Modèles

```bash
# Comparer ByteT5 vs e5-large
./scripts/19_test_embeddings_comparison.sh
```

**Résultat attendu** :

- ✅ Comparaison des performances
- ✅ Comparaison de la pertinence
- ✅ Recommandation du meilleur modèle

---

## 📊 Utilisation dans le Code

### Recherche avec ByteT5 (Existant)

```python
from test_vector_search_base import (
    load_model, encode_text, vector_search,
    connect_to_hcd, get_test_account
)

# Charger le modèle
tokenizer, model = load_model()

# Encoder une requête
query = "LOYER IMPAYE"
embedding = encode_text(tokenizer, model, query)

# Recherche
cluster, session = connect_to_hcd()
results = vector_search(session, embedding, code_si, contrat, limit=5)
```

### Recherche avec e5-large (Nouveau)

```python
from test_vector_search_base_e5 import (
    load_model_e5, encode_text_e5, vector_search_e5,
    connect_to_hcd, get_test_account
)

# Charger le modèle
model = load_model_e5()

# Encoder une requête
query = "LOYER IMPAYE"
embedding = encode_text_e5(model, query)

# Recherche
cluster, session = connect_to_hcd()
results = vector_search_e5(session, embedding, code_si, contrat, limit=5)
```

### Recherche Hybride (Les Deux)

```python
from test_vector_search_base import load_model, encode_text, vector_search
from test_vector_search_base_e5 import load_model_e5, encode_text_e5, vector_search_e5

# Recherche avec ByteT5
tokenizer, model_byt5 = load_model()
embedding_byt5 = encode_text(tokenizer, model_byt5, query)
results_byt5 = vector_search(session, embedding_byt5, code_si, contrat, limit=5)

# Recherche avec e5-large
model_e5 = load_model_e5()
embedding_e5 = encode_text_e5(model_e5, query)
results_e5 = vector_search_e5(session, embedding_e5, code_si, contrat, limit=5)

# Combiner les résultats (déduplication, scoring, etc.)
```

---

## 🔍 Vérification de l'État

### Vérifier les Colonnes

```cql
DESCRIBE TABLE domiramacatops_poc.operations_by_account;
```

**Vérifier** :

- ✅ `libelle_embedding vector<float, 1472>` (ByteT5)
- ✅ `libelle_embedding_e5 vector<float, 1024>` (e5-large)

### Vérifier les Index

```cql
SELECT index_name FROM system_schema.indexes
WHERE keyspace_name = 'domiramacatops_poc'
  AND table_name = 'operations_by_account'
  AND kind = 'CUSTOM'
ALLOW FILTERING;
```

**Vérifier** :

- ✅ `idx_libelle_embedding_vector` (ByteT5)
- ✅ `idx_libelle_embedding_e5_vector` (e5-large)

### Vérifier les Données

```cql
SELECT code_si, contrat, libelle,
       libelle_embedding, libelle_embedding_e5
FROM domiramacatops_poc.operations_by_account
LIMIT 5;
```

**Vérifier** :

- ✅ `libelle_embedding` non NULL (ByteT5)
- ✅ `libelle_embedding_e5` non NULL (e5-large)

---

## 🎯 Stratégies d'Utilisation

### Stratégie 1 : e5-large Seul (RECOMMANDÉ après validation)

**Quand utiliser** :

- Après validation que e5-large est plus pertinent
- Pour simplifier le code
- Pour économiser le stockage (1024 vs 1472 dimensions)

**Code** :

```python
# Utiliser uniquement e5-large
from test_vector_search_base_e5 import load_model_e5, encode_text_e5, vector_search_e5

model = load_model_e5()
embedding = encode_text_e5(model, query)
results = vector_search_e5(session, embedding, code_si, contrat, limit=5)
```

### Stratégie 2 : Hybrid (Les Deux)

**Quand utiliser** :

- Pendant la phase de transition
- Pour comparaison continue
- Pour fallback si un modèle échoue

**Code** :

```python
# Essayer e5-large d'abord
try:
    results = vector_search_e5(session, embedding_e5, code_si, contrat, limit=5)
except:
    # Fallback sur ByteT5
    results = vector_search(session, embedding_byt5, code_si, contrat, limit=5)
```

### Stratégie 3 : Sélection Dynamique

**Quand utiliser** :

- Pour optimiser selon le type de requête
- Pour A/B testing
- Pour optimisation continue

**Code** :

```python
# Sélectionner le modèle selon la requête
if is_french_query(query):
    # Utiliser e5-large pour français
    results = vector_search_e5(session, embedding_e5, code_si, contrat, limit=5)
else:
    # Utiliser ByteT5 pour multilingue
    results = vector_search(session, embedding_byt5, code_si, contrat, limit=5)
```

---

## 📊 Métriques de Performance

### Latence Attendue

| Modèle | Génération Embedding | Recherche HCD | Total |
|--------|---------------------|---------------|-------|
| **ByteT5-small** | 40-50 ms | 5-10 ms | 45-60 ms |
| **e5-large** | 50-100 ms | 5-10 ms | 55-110 ms |

### Stockage

| Modèle | Dimensions | Taille par Embedding | Pour 1M opérations |
|--------|------------|---------------------|-------------------|
| **ByteT5-small** | 1472 | 5.9 KB | ~5.9 GB |
| **e5-large** | 1024 | 4.1 KB | ~4.1 GB |
| **Économie** | - | -30% | ~1.8 GB |

---

## 🔧 Dépannage

### Problème : sentence-transformers non installé

**Solution** :

```bash
pip install sentence-transformers
```

### Problème : Limite SAI atteinte

**Solution** :

- Vérifier les index existants
- Supprimer un index non critique si nécessaire
- Voir `doc/16_SOLUTION_LIMITE_SAI.md`

### Problème : Embeddings e5 non générés

**Solution** :

```bash
# Régénérer les embeddings
./scripts/18_generate_embeddings_e5_auto.sh
```

### Problème : Résultats non pertinents

**Solution** :

1. Vérifier que les données de test pertinentes sont générées
2. Vérifier que les embeddings sont générés
3. Comparer les deux modèles pour choisir le meilleur

---

## 📝 Exemples d'Utilisation

### Exemple 1 : Recherche Simple avec e5-large

```python
from test_vector_search_base_e5 import (
    load_model_e5, encode_text_e5, vector_search_e5,
    connect_to_hcd, get_test_account
)

# Connexion
cluster, session = connect_to_hcd()
account = get_test_account(session)
code_si, contrat = account

# Recherche
model = load_model_e5()
query = "LOYER IMPAYE"
embedding = encode_text_e5(model, query)
results = vector_search_e5(session, embedding, code_si, contrat, limit=5)

# Afficher les résultats
for i, row in enumerate(results, 1):
    print(f"{i}. {row.libelle}")
```

### Exemple 2 : Comparaison des Deux Modèles

```python
from test_vector_search_base import load_model, encode_text, vector_search
from test_vector_search_base_e5 import load_model_e5, encode_text_e5, vector_search_e5

query = "LOYER IMPAYE"

# ByteT5
tokenizer, model_byt5 = load_model()
embedding_byt5 = encode_text(tokenizer, model_byt5, query)
results_byt5 = vector_search(session, embedding_byt5, code_si, contrat, limit=5)

# e5-large
model_e5 = load_model_e5()
embedding_e5 = encode_text_e5(model_e5, query)
results_e5 = vector_search_e5(session, embedding_e5, code_si, contrat, limit=5)

# Comparer
print("ByteT5:", [r.libelle for r in results_byt5])
print("e5-large:", [r.libelle for r in results_e5])
```

---

## ✅ Checklist de Vérification

- [ ] Colonne `libelle_embedding_e5` créée
- [ ] Index `idx_libelle_embedding_e5_vector` créé
- [ ] Données de test pertinentes générées
- [ ] Embeddings e5-large générés
- [ ] sentence-transformers installé
- [ ] Tests comparatifs exécutés
- [ ] Modèle choisi (ByteT5 ou e5-large)

---

**Date de génération** : 2025-11-30  
**Version** : 1.0
