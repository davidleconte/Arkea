# 🔍 Analyse Approfondie des Causes des Incohérences

**Date** : 2025-11-26  
**Script d'analyse** : `analyze_coherence_causes.py`  
**Objectif** : Identifier les causes exactes des incohérences dans les résultats de recherche vectorielle

---

## 📊 Résumé Exécutif

### Problème Identifié

Les tests de recherche vectorielle avec typos retournent des résultats non pertinents malgré :
- ✅ **Données présentes** : Tous les libellés attendus sont présents dans la partition
- ✅ **Embeddings générés** : 100% de couverture (85/85 lignes)
- ✅ **Performance excellente** : < 10ms par requête

### Cause Principale Identifiée

**Les embeddings ByteT5 capturent une similarité SÉMANTIQUE mais pas LEXICALE.**

Les vecteurs d'embedding représentent le **sens** des textes, pas les **mots exacts**. Par conséquent :
- "loyr" (typo) peut être sémantiquement proche de "CB PISCINE PARIS" (transaction bancaire)
- Mais "loyr" n'est pas lexicalement proche de "LOYER" (même si sémantiquement proche)

---

## 🔍 Analyse Détaillée par Test

### TEST 1 : 'loyr' → Devrait trouver 'LOYER'

#### Données Présentes ✅
- **6 libellés pertinents** trouvés dans la partition
- Exemples : "LOYER IMPAYE REGULARISATION", "LOYER PARIS MAISON"
- **Tous ont des embeddings** ✅

#### Similarités Calculées

| Rang | Libellé Pertinent | Similarité Cosinus |
|------|-------------------|-------------------|
| 1 | LOYER IMPAYE REGULARISATION | **0.2279** |
| 2 | REGULARISATION LOYER IMPAYE | 0.2063 |
| 3 | LOYER PARIS MAISON | 0.2051 |
| 4 | LOYER IMPAYE REGULARISATION | 0.2023 |

#### Résultats ANN (Top 5)

| Rang | Libellé | Similarité | Contient LOYER ? |
|------|---------|------------|------------------|
| 1 | CB PISCINE PARIS ABONNEMENT | **0.3052** | ❌ |
| 2 | CB BOLT PARIS TRAJET | 0.3045 | ❌ |
| 3 | CB COIFFEUR PARIS COUPE | 0.3038 | ❌ |
| 4 | CB THEATRE PARIS BILLET | 0.3032 | ❌ |
| 5 | CB PARC ASTRIX ENTREE | 0.3025 | ❌ |

#### Cause Identifiée

**Problème de Similarité Sémantique vs Lexicale** :
- Les libellés pertinents ("LOYER") ont une similarité de **0.2279**
- Les résultats ANN (top 5) ont une similarité de **0.3052** (plus élevée)
- **Aucun résultat pertinent dans le top 20**

**Explication** :
- "loyr" est sémantiquement proche de "CB PISCINE PARIS" (toutes deux sont des transactions bancaires)
- Mais "loyr" n'est pas lexicalement proche de "LOYER" (même si sémantiquement proche)
- ByteT5 capture le **sens** (transaction bancaire) mais pas les **mots exacts** (LOYER)

**Conclusion** : ❌ **Pas un problème de données manquantes** - C'est un problème de **similarité sémantique vs lexicale**

---

### TEST 2 : 'impay' → Devrait trouver 'IMPAYE'

#### Données Présentes ✅
- **13 libellés pertinents** trouvés dans la partition
- Exemples : "VIREMENT IMPAYE REGULARISATION", "LOYER IMPAYE REGULARISATION"
- **Tous ont des embeddings** ✅

#### Similarités Calculées

| Rang | Libellé Pertinent | Similarité Cosinus |
|------|-------------------|-------------------|
| 1 | VIREMENT IMPAYE INSUFFISANCE FONDS | **0.1811** |
| 2 | VIREMENT IMPAYE REMBOURSEMENT | 0.1796 |
| 3 | VIREMENT IMPAYE REGULARISATION | 0.1762 |
| 4 | LOYER IMPAYE REGULARISATION | 0.1439 |

#### Résultats ANN (Top 5)

| Rang | Libellé | Similarité | Contient IMPAYE ? |
|------|---------|------------|-------------------|
| 1 | CB PISCINE PARIS ABONNEMENT | **0.2325** | ❌ |
| 2 | CB COIFFEUR PARIS COUPE | 0.2318 | ❌ |
| 3 | CB THEATRE PARIS BILLET | 0.2312 | ❌ |
| 4 | CB CINEMA MK2 PARIS | 0.2305 | ❌ |
| 5 | CB CINEMA MK2 PARIS | 0.2298 | ❌ |

#### Cause Identifiée

**Même problème que TEST 1** :
- Les libellés pertinents ("IMPAYE") ont une similarité de **0.1811**
- Les résultats ANN (top 5) ont une similarité de **0.2325** (plus élevée)
- **Aucun résultat pertinent dans le top 20**

**Explication** :
- "impay" est sémantiquement proche de "CB PISCINE PARIS" (toutes deux sont des transactions bancaires)
- Mais "impay" n'est pas lexicalement proche de "IMPAYE" (même si sémantiquement proche)

**Conclusion** : ❌ **Pas un problème de données manquantes** - C'est un problème de **similarité sémantique vs lexicale**

---

### TEST 3 : 'viremnt' → Devrait trouver 'VIREMENT'

#### Données Présentes ✅
- **15 libellés pertinents** trouvés dans la partition
- Exemples : "VIREMENT SEPA VERS ASSURANCE VIE", "VIREMENT PERMANENT VERS LIVRET A"
- **Tous ont des embeddings** ✅

#### Similarités Calculées

| Rang | Libellé Pertinent | Similarité Cosinus |
|------|-------------------|-------------------|
| 1 | VIREMENT SEPA VERS ASSURANCE VIE | **0.2489** |
| 2 | VIREMENT PERMANENT VERS LIVRET A | 0.2487 |
| 3 | VIREMENT IMPAYE REMBOURSEMENT | 0.2416 |
| 4 | VIREMENT PERMANENT MENSUEL VERS LIVRET A | 0.2415 |

#### Résultats ANN (Top 20)

| Rang | Libellé | Similarité | Contient VIREMENT ? |
|------|---------|------------|---------------------|
| 1-5 | CB COIFFEUR PARIS COUPE, etc. | 0.2623 | ❌ |
| **6** | **VIREMENT SEPA VERS ASSURANCE VIE** | **0.2489** | **✅** |
| 7 | VIREMENT PERMANENT VERS LIVRET A | 0.2487 | ✅ |
| 8 | VIREMENT IMPAYE REMBOURSEMENT | 0.2416 | ✅ |
| 9 | VIREMENT PERMANENT MENSUEL VERS LIVRET A | 0.2415 | ✅ |

#### Cause Identifiée

**Problème de LIMIT trop restrictif** :
- Les libellés pertinents ("VIREMENT") ont une similarité de **0.2489**
- Les résultats pertinents apparaissent à partir du **rang 6**
- **Cause** : La similarité cosinus n'est pas assez élevée pour être dans le top 5
- Les résultats non pertinents (CB COIFFEUR, etc.) ont une similarité plus élevée (0.2623)

**Explication** :
- "viremnt" est sémantiquement proche de "CB COIFFEUR PARIS" (transaction bancaire)
- Mais "viremnt" est aussi sémantiquement proche de "VIREMENT" (même type d'opération)
- La différence de similarité est faible (0.2623 vs 0.2489), donc les résultats pertinents sont juste après le top 5

**Conclusion** : ⚠️  **Partiellement un problème de LIMIT** - Les résultats pertinents sont au rang 6, mais aussi un problème de **similarité sémantique vs lexicale**

---

## 📊 Synthèse des Causes

### Causes Identifiées

| Test | Données Présentes | Embeddings | Cause Principale | Solution |
|------|-------------------|------------|------------------|----------|
| 'loyr' | ✅ 6 libellés | ✅ 100% | Similarité sémantique vs lexicale | Recherche hybride |
| 'impay' | ✅ 13 libellés | ✅ 100% | Similarité sémantique vs lexicale | Recherche hybride |
| 'viremnt' | ✅ 15 libellés | ✅ 100% | LIMIT + Similarité sémantique | Augmenter LIMIT + Recherche hybride |

### Conclusion Globale

**❌ Ce n'est PAS un problème de données manquantes** :
- ✅ Tous les libellés attendus sont présents
- ✅ Tous les embeddings sont générés (100%)
- ✅ Les libellés pertinents ont des similarités correctes (0.18-0.25)

**✅ C'est un problème de Similarité Sémantique vs Lexicale** :
- Les embeddings ByteT5 capturent le **sens** (transaction bancaire) mais pas les **mots exacts** (LOYER, IMPAYE, VIREMENT)
- Les résultats non pertinents (CB PISCINE PARIS) ont une similarité sémantique plus élevée que les résultats pertinents (LOYER)
- La recherche vectorielle seule ne suffit pas pour des recherches lexicales avec typos

### Solutions Recommandées

1. **Recherche Hybride (Full-Text + Vector)** ⭐ **RECOMMANDÉ**
   - Full-Text pour filtrer les résultats pertinents (mots-clés exacts)
   - Vector pour trier par similarité sémantique
   - Meilleure pertinence globale

2. **Augmenter le LIMIT**
   - Pour 'viremnt', augmenter de 5 à 10 ou 20
   - Les résultats pertinents apparaissent au rang 6
   - Solution partielle (ne résout pas le problème pour 'loyr' et 'impay')

3. **Améliorer les Embeddings**
   - Utiliser un modèle plus performant (ByteT5-base au lieu de ByteT5-small)
   - Fine-tuner le modèle sur des données de typos
   - Augmenter la dimension des embeddings
   - Solution complexe et coûteuse

---

## 🎯 Recommandation Principale

**Utiliser la Recherche Hybride (Full-Text + Vector)** :
- ✅ Combine la précision lexicale (Full-Text) avec la tolérance aux typos (Vector)
- ✅ Résout le problème de similarité sémantique vs lexicale
- ✅ Meilleure pertinence globale
- ✅ Solution déjà disponible : Script 25 (`25_test_hybrid_search_v2_didactique.sh`)

---

**✅ Analyse terminée**


