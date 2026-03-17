# 🔍 Analyse : Modèles d'Embeddings Multiples - Capacité et Recommandations

**Date** : 2025-11-30
**Dernière mise à jour** : 2025-01-XX
**Version** : 1.0
**Objectif** : Analyser la capacité à ajouter d'autres colonnes vectorielles et comparer plusieurs modèles
**Contexte** : Optimisation des embeddings pour le domaine bancaire français

> **Note** : Pour l'analyse du data model et des limites SAI, voir [16_ANALYSE_DATA_MODEL_EMBEDDINGS_MULTIPLES.md](16_ANALYSE_DATA_MODEL_EMBEDDINGS_MULTIPLES.md). Pour le résumé de capacité, voir [16_RESUME_CAPACITE_MODELES_MULTIPLES.md](16_RESUME_CAPACITE_MODELES_MULTIPLES.md). Pour l'implémentation complète, voir [16_RESUME_IMPLEMENTATION_COMPLETE.md](16_RESUME_IMPLEMENTATION_COMPLETE.md).

---

## 📊 État Actuel

### Colonnes Vectorielles Existantes

| Colonne | Modèle | Dimensions | Index SAI | Statut |
|---------|--------|------------|-----------|--------|
| `libelle_embedding` | ByteT5-small | 1472 | `idx_libelle_embedding_vector` | ✅ Existant |
| `libelle_embedding_e5` | multilingual-e5-large | 1024 | `idx_libelle_embedding_e5_vector` | ✅ Créé |

### Index SAI Actuels (10/10 - Limite Atteinte)

| # | Index | Colonne | Type | Priorité | Usage |
|---|-------|---------|------|----------|-------|
| 1 | `idx_libelle_fulltext_advanced` | `libelle` | Full-Text | 🔴 Critique | Recherche full-text |
| 2 | `idx_libelle_embedding_vector` | `libelle_embedding` | Vector | 🔴 Critique | ByteT5 ANN |
| 3 | `idx_libelle_embedding_e5_vector` | `libelle_embedding_e5` | Vector | 🔴 Critique | e5-large ANN |
| 4 | `idx_libelle_prefix_ngram` | `libelle_prefix` | N-Gram | 🟡 Haute | Recherche partielle |
| 5 | `idx_libelle_tokens` | `libelle_tokens` | Collection | 🟡 Haute | CONTAINS |
| 6 | `idx_cat_auto` | `cat_auto` | Equality | 🔴 Critique | Filtrage catégorie |
| 7 | `idx_cat_user` | `cat_user` | Equality | 🟡 Haute | Filtrage client |
| 8 | `idx_montant` | `montant` | Range | 🟡 Haute | Filtrage montant |
| 9 | `idx_type_operation` | `type_operation` | Equality | 🟡 Moyenne | Filtrage type |
| 10 | `idx_meta_source` | `meta_source` | Equality | 🟢 Basse | Filtrage source |

**Total** : **10/10 index SAI** (limite atteinte)

---

## 🎯 Capacité d'Ajout de Modèles

### Scénario 1 : Sans Modification (Limite 10)

**Capacité** : **0 modèle supplémentaire**
**Raison** : Limite SAI atteinte (10/10)

### Scénario 2 : Suppression d'Index Non Critiques

**Index supprimables** (priorité basse/moyenne) :

- `idx_meta_source` (🟢 Basse) - Filtrage par source
- `idx_type_operation` (🟡 Moyenne) - Filtrage par type

**Capacité** : **1-2 modèles supplémentaires**
**Coût** : Perte de capacité de filtrage (peut utiliser ALLOW FILTERING si nécessaire)

### Scénario 3 : Augmentation de la Limite SAI

**Configuration HCD** :

```yaml
# Dans cassandra.yaml ou configuration HCD
sai_index_max_per_table: 15  # Au lieu de 10 par défaut
```

**Capacité** : **5 modèles supplémentaires** (jusqu'à 15 index)
**Coût** : Impact sur les performances (plus d'index = plus de maintenance)

---

## 🏆 Modèles Recommandés pour le Domaine Bancaire

### Modèles Actuellement Testés

1. ✅ **ByteT5-small** (`google/byt5-small`)
   - Dimensions : 1472
   - Avantages : Rapide, multilingue, bon pour "CB"
   - Inconvénients : Pertinence faible (0-25%)

2. ✅ **multilingual-e5-large** (`intfloat/multilingual-e5-large`)
   - Dimensions : 1024
   - Avantages : Meilleure pertinence (50%), excellent français
   - Inconvénients : Plus lent, modèle plus grand

### Modèles Supplémentaires Recommandés

#### 1. **Invoices_bilingual-embedding-large** (RECOMMANDÉ - Spécialisé Facturation)

- **Modèle** : `NoureddineSa/Invoices_bilingual-embedding-large`
- **Dimensions** : À vérifier (probablement 768-1024)
- **Avantages** :
  - ✅ **Spécialisé facturation/invoices** - Optimisé pour documents financiers
  - ✅ **Bilingue FR/EN** - Support français natif
  - ✅ **Meilleure compréhension terminologie bancaire** - LOYER, VIREMENT, TAXE, etc.
  - ✅ **Optimisé pour documents structurés** - Format factures/paiements
- **Inconvénients** :
  - ⚠️ Peut être moins performant sur libellés très courts
  - ⚠️ Moins généraliste que e5-base
- **Usage** : **PRIORITÉ 1** - Pour libellés bancaires/facturation

#### 2. **multilingual-e5-base** (ALTERNATIVE)

- **Modèle** : `intfloat/multilingual-e5-base`
- **Dimensions** : 768
- **Avantages** :
  - ✅ Plus rapide que e5-large (modèle plus petit)
  - ✅ Bon compromis performance/pertinence
  - ✅ Support multilingue excellent
- **Inconvénients** :
  - ⚠️ Moins spécialisé facturation
  - ⚠️ Pertinence légèrement inférieure à e5-large
- **Usage** : Alternative si modèle facturation non disponible

#### 2. **paraphrase-multilingual-MiniLM** (RECOMMANDÉ)

- **Modèle** : `paraphrase-multilingual-MiniLM-L12-v2`
- **Dimensions** : 384
- **Avantages** :
  - ✅ Très rapide (modèle très petit)
  - ✅ Optimisé pour similarité sémantique
  - ✅ Support multilingue
- **Inconvénients** :
  - ⚠️ Pertinence peut être inférieure aux modèles plus grands
- **Usage** : Pour recherche rapide avec volume élevé

#### 3. **sentence-transformers/all-MiniLM-L6-v2** (OPTIONNEL)

- **Modèle** : `sentence-transformers/all-MiniLM-L6-v2`
- **Dimensions** : 384
- **Avantages** :
  - ✅ Très rapide
  - ✅ Modèle très populaire et bien testé
- **Inconvénients** :
  - ⚠️ Support français moins bon que les modèles multilingues
- **Usage** : Benchmark de performance

#### 4. **camembert-base** (OPTIONNEL - Spécialisé Français)

- **Modèle** : `dangvantuan/sentence-camembert-base`
- **Dimensions** : 768
- **Avantages** :
  - ✅ Spécialisé français (meilleur pour français pur)
  - ✅ Bonne compréhension du contexte français
- **Inconvénients** :
  - ⚠️ Pas multilingue (uniquement français)
  - ⚠️ Moins adapté si données multilingues
- **Usage** : Si données 100% françaises

#### 5. **LaBSE** (OPTIONNEL - Multilingue Avancé)

- **Modèle** : `sentence-transformers/LaBSE`
- **Dimensions** : 768
- **Avantages** :
  - ✅ Excellent support multilingue (109 langues)
  - ✅ Bonne performance cross-lingue
- **Inconvénients** :
  - ⚠️ Modèle plus ancien (2020)
  - ⚠️ Peut être moins performant que e5
- **Usage** : Si besoin de support multilingue très large

---

## 📊 Comparaison des Modèles

| Modèle | Dimensions | Taille | Latence | Pertinence | Multilingue | Français | Recommandation |
|--------|------------|--------|---------|------------|-------------|----------|----------------|
| **ByteT5-small** | 1472 | 60M | ⚡⚡⚡ (55ms) | ⭐⭐ (25%) | ✅ | ⭐⭐ | ✅ Existant |
| **e5-large** | 1024 | 560M | ⚡ (3218ms*) | ⭐⭐⭐⭐ (50%) | ✅ | ⭐⭐⭐⭐ | ✅ Existant |
| **e5-base** | 768 | 278M | ⚡⚡ (est. 200ms) | ⭐⭐⭐ (est. 40%) | ✅ | ⭐⭐⭐ | 🥇 **Recommandé** |
| **MiniLM-L12** | 384 | 42M | ⚡⚡⚡ (est. 30ms) | ⭐⭐ (est. 30%) | ✅ | ⭐⭐⭐ | 🥈 **Recommandé** |
| **all-MiniLM-L6** | 384 | 22M | ⚡⚡⚡ (est. 25ms) | ⭐⭐ (est. 25%) | ⚠️ | ⭐⭐ | 🥉 Optionnel |
| **Camembert** | 768 | 110M | ⚡⚡ (est. 150ms) | ⭐⭐⭐ (est. 35%) | ❌ | ⭐⭐⭐⭐ | Optionnel (FR) |
| **LaBSE** | 768 | 471M | ⚡ (est. 500ms) | ⭐⭐⭐ (est. 35%) | ✅ | ⭐⭐⭐ | Optionnel |

*Latence e5-large inclut le chargement du modèle (premier appel). Après cache : ~50-100ms.

---

## 🎯 Recommandations par Scénario

### Scénario A : Maximum 2 Modèles (Sans Modification)

**Recommandation** : **Garder ByteT5 + e5-large** (déjà implémenté)

**Justification** :

- ✅ Couverture complète (rapide + pertinent)
- ✅ ByteT5 excelle pour "CB" (100% pertinence)
- ✅ e5-large excelle pour la plupart des requêtes (50% pertinence)
- ✅ Stratégie hybride optimale

### Scénario B : 3 Modèles (Supprimer 1 Index) - RECOMMANDÉ

**Recommandation** : **ByteT5 + e5-large + Modèle Facturation**

**Actions** :

1. Supprimer `idx_meta_source` (priorité basse)
2. Ajouter `libelle_embedding_invoice VECTOR<FLOAT, 768-1024>` (dimensions à vérifier)
3. Créer `idx_libelle_embedding_invoice_vector`

**Avantages** :

- ✅ **Modèle spécialisé facturation** : Meilleure compréhension terminologie bancaire
- ✅ **Optimisé pour libellés financiers** : LOYER, VIREMENT, TAXE, ASSURANCE, etc.
- ✅ **Comparaison spécialisé vs généraliste** : Facturation vs e5-large
- ✅ **Pertinence supérieure attendue** pour libellés bancaires

**Alternative** : Si modèle facturation non disponible, utiliser e5-base

### Scénario C : 4 Modèles (Supprimer 2 Index)

**Recommandation** : **ByteT5 + e5-large + e5-base + MiniLM-L12**

**Actions** :

1. Supprimer `idx_meta_source` et `idx_type_operation`
2. Ajouter `libelle_embedding_e5_base` (768 dim)
3. Ajouter `libelle_embedding_minilm` (384 dim)
4. Créer les index correspondants

**Avantages** :

- ✅ Couverture complète : rapide (MiniLM) + équilibré (e5-base) + optimal (e5-large)
- ✅ Comparaison complète des stratégies
- ✅ Choix optimal selon le cas d'usage

### Scénario D : 5+ Modèles (Augmenter Limite SAI)

**Recommandation** : **Tous les modèles recommandés**

**Actions** :

1. Augmenter limite SAI à 15 (configuration HCD)
2. Ajouter tous les modèles recommandés
3. Comparaison exhaustive

**Avantages** :

- ✅ Comparaison exhaustive de tous les modèles
- ✅ Choix optimal basé sur données réelles
- ✅ Flexibilité maximale

**Inconvénients** :

- ⚠️ Impact sur les performances (plus d'index)
- ⚠️ Complexité de maintenance
- ⚠️ Stockage accru

---

## 💾 Impact Stockage

### Stockage par Modèle (pour 1M opérations)

| Modèle | Dimensions | Taille/Embedding | Total (1M ops) |
|--------|------------|------------------|----------------|
| ByteT5-small | 1472 | 5.9 KB | ~5.9 GB |
| e5-large | 1024 | 4.1 KB | ~4.1 GB |
| e5-base | 768 | 3.1 KB | ~3.1 GB |
| MiniLM-L12 | 384 | 1.5 KB | ~1.5 GB |

### Stockage Total selon Scénario

- **2 modèles** (ByteT5 + e5-large) : ~10 GB
- **3 modèles** (+ e5-base) : ~13.1 GB
- **4 modèles** (+ MiniLM) : ~14.6 GB
- **5 modèles** (+ Camembert) : ~17.7 GB

---

## ✅ Recommandation Finale

### Pour le POC (Recommandé)

**Scénario B : 3 Modèles** (ByteT5 + e5-large + Modèle Facturation)

**Justification** :

- ✅ **Modèle spécialisé facturation** : Plus pertinent pour libellés bancaires
- ✅ **Comparaison spécialisé vs généraliste** : Facturation vs e5-large
- ✅ Impact minimal (suppression d'1 index non critique)
- ✅ Stockage raisonnable (~13 GB pour 1M ops)
- ✅ Couverture complète des cas d'usage bancaire

**Modèle recommandé** : `NoureddineSa/Invoices_bilingual-embedding-large`

### Pour la Production (Selon Besoins)

**Option 1** : **2 Modèles** (ByteT5 + e5-large)

- Si limite SAI stricte
- Stratégie hybride optimale

**Option 2** : **3 Modèles** (ByteT5 + e5-large + e5-base)

- Si besoin de fallback rapide
- Comparaison performance/pertinence

**Option 3** : **4 Modèles** (ByteT5 + e5-large + e5-base + MiniLM)

- Si besoin de recherche très rapide
- Comparaison exhaustive

---

## 📝 Prochaines Étapes

1. ✅ **Décider du scénario** (2, 3, ou 4 modèles)
2. ⚠️ **Supprimer index non critiques** (si nécessaire)
3. ⚠️ **Créer colonnes vectorielles** (si nécessaire)
4. ⚠️ **Créer index SAI** (si nécessaire)
5. ⚠️ **Générer embeddings** (si nécessaire)
6. ⚠️ **Comparer les modèles** (si nécessaire)

---

**Date de génération** : 2025-11-30
**Version** : 1.0
