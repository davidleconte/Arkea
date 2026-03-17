# 🔧 Solution : Limite SAI Atteinte

**Date** : 2025-01-XX
**Problème** : Limite de 10 index SAI par table atteinte
**Table** : `operations_by_account`

---

## 📊 État Actuel

### Index SAI Existants (10/10)

| # | Index | Colonne | Type | Usage | Priorité |
|---|-------|---------|------|-------|----------|
| 1 | `idx_libelle_fulltext_advanced` | `libelle` | Full-Text | Recherche full-text | 🔴 Critique |
| 2 | `idx_libelle_embedding_vector` | `libelle_embedding` | Vector | Recherche vectorielle ByteT5 | 🔴 Critique |
| 3 | `idx_libelle_prefix_ngram` | `libelle_prefix` | N-Gram | Recherche partielle | 🟡 Haute |
| 4 | `idx_libelle_tokens` | `libelle_tokens` | Collection | Recherche avec CONTAINS | 🟡 Haute |
| 5 | `idx_cat_auto` | `cat_auto` | Equality | Filtrage par catégorie | 🔴 Critique |
| 6 | `idx_cat_user` | `cat_user` | Equality | Filtrage par catégorie client | 🟡 Haute |
| 7 | `idx_montant` | `montant` | Range | Filtrage par montant | 🟡 Haute |
| 8 | `idx_type_operation` | `type_operation` | Equality | Filtrage par type | 🟡 Moyenne |
| 9 | `idx_meta_source` | `meta_source` | Equality | Filtrage par source | 🟢 Basse |
| 10 | `idx_meta_device` | `meta_device` | Equality | Filtrage par device | 🟢 Basse |

**Total** : **10/10 index SAI** (limite atteinte)

---

## 🎯 Solutions Proposées

### Option 1 : Supprimer un Index Meta (RECOMMANDÉ)

**Stratégie** : Supprimer `idx_meta_device` (priorité basse) pour libérer un slot.

**Avantages** :
- ✅ Libère un slot pour l'index e5-large
- ✅ Impact minimal (index meta peu utilisé)
- ✅ Solution simple et rapide

**Inconvénients** :
- ⚠️ Perte de capacité de filtrage par device
- ⚠️ Nécessite ALLOW FILTERING si besoin (non recommandé)

**Action** :
```cql
-- Supprimer l'index meta_device
DROP INDEX IF EXISTS idx_meta_device;

-- Créer l'index e5-large
CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_embedding_e5_vector
ON operations_by_account(libelle_embedding_e5)
USING 'StorageAttachedIndex'
WITH OPTIONS = {'similarity_function': 'COSINE'};
```

---

### Option 2 : Supprimer Plusieurs Index Meta (OPTIMAL)

**Stratégie** : Supprimer `idx_meta_device` ET `idx_meta_source` pour libérer 2 slots.

**Avantages** :
- ✅ Libère 2 slots (1 pour e5-large + 1 de réserve)
- ✅ Impact minimal (index meta peu utilisés)
- ✅ Plus de flexibilité future

**Action** :
```cql
-- Supprimer les index meta
DROP INDEX IF EXISTS idx_meta_device;
DROP INDEX IF EXISTS idx_meta_source;

-- Créer l'index e5-large
CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_embedding_e5_vector
ON operations_by_account(libelle_embedding_e5)
USING 'StorageAttachedIndex'
WITH OPTIONS = {'similarity_function': 'COSINE'};
```

---

### Option 3 : Recherche Vectorielle Sans Index (NON RECOMMANDÉ)

**Stratégie** : Utiliser la colonne `libelle_embedding_e5` sans index SAI.

**Avantages** :
- ✅ Pas besoin de supprimer d'index
- ✅ Colonne disponible pour stockage

**Inconvénients** :
- ❌ Pas de recherche ANN optimisée
- ❌ Nécessite scan complet + calcul de similarité côté client
- ❌ Performance très dégradée
- ❌ Non viable en production

---

### Option 4 : Augmenter la Limite SAI (AVANCÉ)

**Stratégie** : Modifier la configuration HCD pour augmenter la limite.

**Avantages** :
- ✅ Garde tous les index existants
- ✅ Ajoute l'index e5-large

**Inconvénients** :
- ⚠️ Nécessite modification de configuration HCD
- ⚠️ Impact sur les performances (plus d'index = plus de maintenance)
- ⚠️ Non recommandé par défaut

**Configuration** :
```yaml
# Dans cassandra.yaml ou configuration HCD
sai_index_max_per_table: 15  # Au lieu de 10 par défaut
```

---

## ✅ Recommandation : Option 2

**Supprimer `idx_meta_device` et `idx_meta_source`**

**Justification** :
1. ✅ Index meta peu utilisés dans les tests actuels
2. ✅ Libère 2 slots (1 pour e5-large + 1 de réserve)
3. ✅ Impact minimal sur les fonctionnalités
4. ✅ Solution simple et rapide

---

## 📋 Script de Migration

**Script à créer** : `scripts/17_add_e5_embedding_column_v2.sh`

**Actions** :
1. Supprimer `idx_meta_device`
2. Supprimer `idx_meta_source` (optionnel)
3. Créer `idx_libelle_embedding_e5_vector`
4. Vérifier les index

---

**Date de génération** : 2025-11-30
**Version** : 1.0
