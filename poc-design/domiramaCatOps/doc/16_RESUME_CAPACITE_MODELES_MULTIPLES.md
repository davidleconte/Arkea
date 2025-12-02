# 📊 Résumé : Capacité d'Ajout de Modèles d'Embeddings

**Date** : 2025-11-30  
**Dernière mise à jour** : 2025-01-XX  
**Version** : 1.0  
**Question** : Peut-on ajouter d'autres colonnes vectorielles ? Combien de modèles peut-on comparer ?

> **Note** : Pour l'analyse détaillée du data model, voir [16_ANALYSE_DATA_MODEL_EMBEDDINGS_MULTIPLES.md](16_ANALYSE_DATA_MODEL_EMBEDDINGS_MULTIPLES.md). Pour l'analyse des modèles et recommandations, voir [16_ANALYSE_MODELES_EMBEDDINGS_MULTIPLES.md](16_ANALYSE_MODELES_EMBEDDINGS_MULTIPLES.md). Pour l'implémentation complète, voir [16_RESUME_IMPLEMENTATION_COMPLETE.md](16_RESUME_IMPLEMENTATION_COMPLETE.md).

---

## ✅ Réponse Rapide

**Oui, on peut ajouter d'autres colonnes vectorielles**, mais il y a une **limite de 10 index SAI par table**.

**Actuellement** :

- ✅ **2 modèles** : ByteT5-small + multilingual-e5-large
- ✅ **10/10 index SAI** utilisés (limite atteinte)
- ⚠️ **0 slot disponible** pour nouveaux modèles

**Capacité selon scénario** :

- **Sans modification** : 0 modèle supplémentaire
- **Supprimer 1 index** : 1 modèle supplémentaire (3 modèles total)
- **Supprimer 2 index** : 2 modèles supplémentaires (4 modèles total)
- **Augmenter limite SAI** : 5+ modèles supplémentaires (jusqu'à 15 index)

---

## 📊 État Actuel

### Colonnes Vectorielles

| Colonne | Modèle | Dimensions | Index SAI |
|---------|--------|------------|-----------|
| `libelle_embedding` | ByteT5-small | 1472 | ✅ `idx_libelle_embedding_vector` |
| `libelle_embedding_e5` | multilingual-e5-large | 1024 | ✅ `idx_libelle_embedding_e5_vector` |

### Index SAI (10/10)

| # | Index | Type | Priorité |
|---|-------|------|----------|
| 1 | `idx_libelle_fulltext_advanced` | Full-Text | 🔴 Critique |
| 2 | `idx_libelle_embedding_vector` | Vector | 🔴 Critique |
| 3 | `idx_libelle_embedding_e5_vector` | Vector | 🔴 Critique |
| 4 | `idx_libelle_prefix_ngram` | N-Gram | 🟡 Haute |
| 5 | `idx_libelle_tokens` | Collection | 🟡 Haute |
| 6 | `idx_cat_auto` | Equality | 🔴 Critique |
| 7 | `idx_cat_user` | Equality | 🟡 Haute |
| 8 | `idx_montant` | Range | 🟡 Haute |
| 9 | `idx_type_operation` | Equality | 🟡 Moyenne |
| 10 | `idx_meta_source` | Equality | 🟢 Basse |

**Total** : **10/10** (limite atteinte)

---

## 🎯 Scénarios Possibles

### Scénario 1 : 3 Modèles (RECOMMANDÉ)

**Action** : Supprimer `idx_meta_source` (priorité basse)

**Modèles** :

1. ✅ ByteT5-small (existant)
2. ✅ e5-large (existant)
3. 🆕 **Modèle Facturation** (`NoureddineSa/Invoices_bilingual-embedding-large`, dimensions à vérifier)

**Avantages** :

- ✅ **Modèle spécialisé facturation** : Plus pertinent pour libellés bancaires
- ✅ **Comparaison spécialisé vs généraliste** : Facturation vs e5-large
- ✅ **Meilleure compréhension terminologie bancaire** : LOYER, VIREMENT, TAXE, etc.
- ✅ Impact minimal (1 index non critique supprimé)

**Alternative** : Si modèle facturation non disponible, utiliser e5-base

**Stockage** : ~13 GB pour 1M opérations

---

### Scénario 2 : 4 Modèles

**Action** : Supprimer `idx_meta_source` + `idx_type_operation`

**Modèles** :

1. ✅ ByteT5-small
2. ✅ e5-large
3. 🆕 e5-base
4. 🆕 **MiniLM-L12** (`paraphrase-multilingual-MiniLM-L12-v2`, 384 dim)

**Avantages** :

- ✅ Couverture complète : rapide (MiniLM) + équilibré (e5-base) + optimal (e5-large)
- ✅ Comparaison exhaustive

**Stockage** : ~14.6 GB pour 1M opérations

---

### Scénario 3 : 5+ Modèles (Augmenter Limite)

**Action** : Modifier configuration HCD (`sai_index_max_per_table: 15`)

**Modèles** :

1. ✅ ByteT5-small
2. ✅ e5-large
3. 🆕 e5-base
4. 🆕 MiniLM-L12
5. 🆕 **Camembert** (spécialisé français, 768 dim)

**Avantages** :

- ✅ Comparaison exhaustive
- ✅ Choix optimal basé sur données réelles

**Inconvénients** :

- ⚠️ Impact sur performances
- ⚠️ Complexité de maintenance

---

## 🏆 Modèles Recommandés

### 1. Invoices_bilingual-embedding-large (PRIORITÉ 1 - Spécialisé Facturation)

- **Modèle** : `NoureddineSa/Invoices_bilingual-embedding-large`
- **Dimensions** : À vérifier (probablement 768-1024)
- **Avantages** :
  - ✅ Spécialisé facturation/invoices
  - ✅ Meilleure compréhension terminologie bancaire
  - ✅ Optimisé pour documents structurés
- **Usage** : **PRIORITÉ 1** - Pour libellés bancaires/facturation

### 2. multilingual-e5-base (ALTERNATIVE)

- **Modèle** : `intfloat/multilingual-e5-base`
- **Dimensions** : 768
- **Avantages** : Plus rapide que e5-large, bon compromis
- **Usage** : Alternative si modèle facturation non disponible

### 2. paraphrase-multilingual-MiniLM (PRIORITÉ 2)

- **Modèle** : `paraphrase-multilingual-MiniLM-L12-v2`
- **Dimensions** : 384
- **Avantages** : Très rapide, optimisé similarité
- **Usage** : Recherche rapide haute performance

### 3. sentence-camembert-base (PRIORITÉ 3)

- **Modèle** : `dangvantuan/sentence-camembert-base`
- **Dimensions** : 768
- **Avantages** : Spécialisé français
- **Usage** : Si données 100% françaises

---

## 📋 Comparaison des Modèles

| Modèle | Dimensions | Latence | Pertinence | Recommandation |
|--------|------------|---------|------------|----------------|
| **ByteT5-small** | 1472 | ⚡⚡⚡ (55ms) | ⭐⭐ (25%) | ✅ Existant |
| **e5-large** | 1024 | ⚡ (3218ms*) | ⭐⭐⭐⭐ (50%) | ✅ Existant |
| **e5-base** | 768 | ⚡⚡ (est. 200ms) | ⭐⭐⭐ (est. 40%) | 🥇 **Recommandé** |
| **MiniLM-L12** | 384 | ⚡⚡⚡ (est. 30ms) | ⭐⭐ (est. 30%) | 🥈 **Recommandé** |
| **Camembert** | 768 | ⚡⚡ (est. 150ms) | ⭐⭐⭐ (est. 35%) | 🥉 Optionnel |

*Latence e5-large inclut chargement modèle (premier appel). Après cache : ~50-100ms.

---

## ✅ Recommandation Finale

### Pour le POC : **3 Modèles** (Scénario 1)

**Justification** :

- ✅ **Modèle spécialisé facturation** : Plus pertinent pour libellés bancaires
- ✅ Comparaison pertinente (ByteT5 vs e5-large vs facturation)
- ✅ Impact minimal (suppression d'1 index non critique)
- ✅ Stockage raisonnable (~13 GB)
- ✅ Couverture complète des cas d'usage bancaire

**Modèles** :

1. ByteT5-small (rapide, bon pour "CB")
2. e5-large (optimal généraliste, meilleure pertinence globale)
3. **Modèle Facturation** (spécialisé, meilleure pertinence bancaire)

**Modèle recommandé** : `NoureddineSa/Invoices_bilingual-embedding-large`

---

## 🚀 Prochaines Étapes

1. **Décider du scénario** (2, 3, ou 4 modèles)
2. **Supprimer index non critiques** (si nécessaire)
3. **Créer colonnes vectorielles** (si nécessaire)
4. **Créer index SAI** (si nécessaire)
5. **Générer embeddings** (si nécessaire)
6. **Comparer les modèles** (si nécessaire)

---

**Date de génération** : 2025-11-30  
**Version** : 1.0
