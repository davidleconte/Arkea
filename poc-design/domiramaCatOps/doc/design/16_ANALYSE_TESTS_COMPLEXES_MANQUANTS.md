# 🔍 Analyse : Tests Complexes Manquants pour Couvrir le Périmètre Complet

**Date** : 2025-01-XX  
**Dernière mise à jour** : 2025-01-XX  
**Version** : 2.0  
**Objectif** : Identifier les tests complexes pertinents manquants pour couvrir le périmètre du cas d'usage déduit de inputs-clients et inputs-ibm

---

## 📊 Résumé Exécutif

**Tests complexes identifiés** : **15 catégories**  
**Tests déjà implémentés** : **8 catégories**  
**Tests manquants** : **7 catégories** (priorité haute/moyenne)

**Score de couverture** : **53%** - ⚠️ **Tests complexes supplémentaires nécessaires**

---

## 📋 PARTIE 1 : Tests Complexes Déjà Implémentés

### 1.1 Tests de Recherche Vectorielle (✅ Couvert)

| Test | Description | Script | Statut |
|------|-------------|--------|--------|
| **TC-01** | Recherche vectorielle basique | `test_vector_search.py` | ✅ |
| **TC-02** | Recherche avec typos | `test_vector_search_robustness.py` | ✅ |
| **TC-03** | Recherche avec accents | `test_vector_search_accents.py` | ✅ |
| **TC-04** | Recherche multilingue | `test_vector_search_multilang.py` | ✅ |
| **TC-05** | Recherche avec synonymes | `test_vector_search_synonyms.py` | ✅ |
| **TC-06** | Recherche avec seuils | `test_vector_search_threshold.py` | ✅ |
| **TC-07** | Recherche hybride | `hybrid_search_v2.py` | ✅ |

**✅ 7 tests de recherche vectorielle couverts**

---

### 1.2 Tests de Performance (✅ Couvert)

| Test | Description | Script | Statut |
|------|-------------|--------|--------|
| **TC-08** | Latence recherche | `test_vector_search_performance.py` | ✅ |
| **TC-09** | Volume de données | `test_vector_search_volume.py` | ✅ |

**✅ 2 tests de performance couverts**

---

### 1.3 Tests de Robustesse (✅ Couvert)

| Test | Description | Script | Statut |
|------|-------------|--------|--------|
| **TC-10** | Cas limites (NULL, caractères spéciaux) | `test_vector_search_robustness.py` | ✅ |
| **TC-11** | Cohérence résultats | `test_vector_search_consistency.py` | ✅ |

**✅ 2 tests de robustesse couverts**

---

## 📋 PARTIE 2 : Tests Complexes Manquants (Priorité Haute)

### 2.1 Tests de Migration Complexe (❌ MANQUANT)

**Contexte** : Inputs-clients mentionnent `FullScan + STARTROW + STOPROW + TIMERANGE` pour unload incrémentaux

#### TC-MISS-01 : Migration Incrémentale avec Validation

**Description** :
- Export par plages (STARTROW/STOPROW équivalents)
- Validation cohérence source vs export
- Gestion des doublons
- Reprise après interruption

**Complexité** : 🔴 **Haute**

**Tests à Implémenter** :
1. Export par plages précises (code_si + contrat + date_op + numero_op)
2. Validation cohérence (comptage, vérification intégrité)
3. Gestion des doublons (déduplication)
4. Reprise après interruption (checkpointing)
5. Validation multi-tables (cohérence entre tables)

**Script à créer** : `20_test_migration_complexe.sh`

---

#### TC-MISS-02 : Migration avec Fenêtre Glissante Complexe

**Description** :
- Fenêtre glissante avec chevauchement
- Validation cohérence entre fenêtres
- Gestion des frontières (début/fin de période)
- Agrégation multi-fenêtres

**Complexité** : 🔴 **Haute**

**Tests à Implémenter** :
1. Fenêtre glissante avec chevauchement (validation pas de doublons)
2. Fenêtre glissante sans chevauchement (validation complétude)
3. Gestion des frontières (première/dernière fenêtre)
4. Agrégation multi-fenêtres (statistiques globales)

**Script à créer** : `20_test_fenetre_glissante_complexe.sh`

---

### 2.2 Tests de Cohérence Multi-Tables Complexe (⚠️ PARTIEL)

**Contexte** : Inputs-clients mentionnent cohérence entre `domirama` et `domirama-meta-categories`

#### TC-MISS-03 : Cohérence Transactionnelle Multi-Tables

**Description** :
- Validation cohérence entre plusieurs tables simultanément
- Tests de référentiel (foreign keys équivalents)
- Tests de contraintes métier complexes
- Tests de cohérence temporelle

**Complexité** : 🔴 **Haute**

**Tests à Implémenter** :
1. Cohérence référentielle (acceptation_client → operations_by_account)
2. Cohérence temporelle (dates cohérentes entre tables)
3. Cohérence compteurs (feedbacks_count = SUM feedbacks)
4. Cohérence historique (historique_opposition → opposition_categorisation)
5. Cohérence règles (regles_personnalisees → cat_auto)

**Script à créer** : `20_test_coherence_transactionnelle.sh`

---

#### TC-MISS-04 : Tests de Contraintes Métier Complexes

**Description** :
- Validation règles métier (ex: cat_user ne peut pas être modifié si accepté)
- Validation contraintes temporelles (ex: date_op <= date_valeur)
- Validation contraintes logiques (ex: cat_auto doit exister dans regles_personnalisees)

**Complexité** : 🟡 **Moyenne-Haute**

**Tests à Implémenter** :
1. Contraintes métier (règles de validation)
2. Contraintes temporelles (dates cohérentes)
3. Contraintes logiques (cohérence catégories)
4. Contraintes d'intégrité (pas de références orphelines)

**Script à créer** : `20_test_contraintes_metier.sh`

---

### 2.3 Tests de Performance Sous Charge (❌ MANQUANT)

**Contexte** : Inputs-IBM mentionnent performance et scalabilité

#### TC-MISS-05 : Tests de Charge Concurrente

**Description** :
- Lectures simultanées multiples
- Écritures simultanées multiples
- Mix lectures/écritures simultanées
- Mesure dégradation performance

**Complexité** : 🔴 **Haute**

**Tests à Implémenter** :
1. Charge lecture (100+ requêtes simultanées)
2. Charge écriture (100+ insertions simultanées)
3. Charge mixte (50% lecture, 50% écriture)
4. Mesure latence sous charge
5. Mesure throughput sous charge
6. Détection de goulots d'étranglement

**Script à créer** : `20_test_charge_concurrente.sh`

---

#### TC-MISS-06 : Tests de Scalabilité

**Description** :
- Performance avec volumes croissants (10K, 100K, 1M, 10M opérations)
- Performance avec index multiples
- Performance avec recherche hybride multi-modèles
- Dégradation performance selon volume

**Complexité** : 🟡 **Moyenne-Haute**

**Tests à Implémenter** :
1. Scalabilité volume (10K → 10M opérations)
2. Scalabilité index (1 → 10 index SAI)
3. Scalabilité modèles (1 → 3 modèles vectoriels)
4. Analyse dégradation (latence vs volume)
5. Recommandations seuils de performance

**Script à créer** : `20_test_scalabilite.sh`

---

### 2.4 Tests de Recherche Complexe Multi-Modèles (⚠️ PARTIEL)

**Contexte** : Maintenant que nous avons 3 modèles (ByteT5, e5-large, Facturation)

#### TC-MISS-07 : Recherche Hybride Multi-Modèles avec Fusion

**Description** :
- Recherche avec plusieurs modèles simultanément
- Fusion des résultats (déduplication, scoring combiné)
- Ranking personnalisé (score combiné)
- Fallback automatique (modèle 1 → modèle 2 → modèle 3)

**Complexité** : 🔴 **Haute**

**Tests à Implémenter** :
1. Recherche multi-modèles simultanée (ByteT5 + e5-large + Facturation)
2. Fusion résultats (déduplication, scoring combiné)
3. Ranking personnalisé (score = moyenne pondérée)
4. Fallback automatique (si modèle 1 échoue → modèle 2)
5. Comparaison pertinence multi-modèles vs mono-modèle

**Script à créer** : `20_test_recherche_multi_modeles_fusion.sh`

---

#### TC-MISS-08 : Recherche avec Filtres Multiples Combinés

**Description** :
- Vector + Full-Text + Filtres (date, montant, catégorie) simultanément
- Optimisation requête (ordre des filtres)
- Performance avec filtres multiples
- Validation résultats (tous les filtres respectés)

**Complexité** : 🟡 **Moyenne-Haute**

**Tests à Implémenter** :
1. Vector + Full-Text + Date + Montant + Catégorie
2. Optimisation ordre filtres (filtres sélectifs d'abord)
3. Performance avec filtres multiples (latence)
4. Validation résultats (tous les filtres respectés)
5. Cas limites (aucun résultat, trop de résultats)

**Script à créer** : `20_test_recherche_filtres_multiples.sh`

---

### 2.5 Tests de Résilience (❌ MANQUANT)

**Contexte** : Inputs-clients mentionnent patterns de production (erreurs, timeouts, retry)

#### TC-MISS-09 : Tests de Résilience (Erreurs, Timeouts, Retry)

**Description** :
- Gestion erreurs (connexion perdue, timeout)
- Retry automatique (stratégie exponential backoff)
- Fallback (modèle 1 → modèle 2 si erreur)
- Validation reprise après erreur

**Complexité** : 🟡 **Moyenne**

**Tests à Implémenter** :
1. Simulation erreur connexion (reconnexion automatique)
2. Simulation timeout (retry avec backoff)
3. Simulation erreur modèle (fallback automatique)
4. Validation reprise après erreur (données cohérentes)
5. Mesure impact erreurs (latence, throughput)

**Script à créer** : `20_test_resilience.sh`

---

#### TC-MISS-10 : Tests de Disponibilité (Failover)

**Description** :
- Simulation panne nœud (failover automatique)
- Validation cohérence après failover
- Performance après failover
- Reprise service (recovery)

**Complexité** : 🔴 **Haute** (nécessite cluster multi-nœuds)

**Tests à Implémenter** :
1. Simulation panne nœud (si cluster disponible)
2. Validation failover (requêtes continuent)
3. Validation cohérence (données accessibles)
4. Performance après failover (dégradation acceptable)
5. Reprise service (recovery automatique)

**Script à créer** : `20_test_failover.sh` (si cluster disponible)

---

### 2.6 Tests d'Agrégation et Analytics (❌ MANQUANT)

**Contexte** : Inputs-clients mentionnent unload ORC pour analyse

#### TC-MISS-11 : Tests d'Agrégation Complexe

**Description** :
- Agrégations temporelles (COUNT, SUM, AVG par période)
- Agrégations par catégorie (groupement)
- Agrégations combinées (date + catégorie)
- Performance agrégations

**Complexité** : 🟡 **Moyenne**

**Tests à Implémenter** :
1. Agrégations temporelles (COUNT par jour, semaine, mois)
2. Agrégations par catégorie (SUM montant par cat_auto)
3. Agrégations combinées (SUM montant par date + catégorie)
4. Performance agrégations (latence)
5. Validation résultats (cohérence avec données source)

**Script à créer** : `20_test_aggregations.sh`

---

#### TC-MISS-12 : Tests de Facettes (Groupement)

**Description** :
- Groupement par catégorie (facettes)
- Groupement par date (facettes temporelles)
- Groupement combiné (multi-facettes)
- Performance facettes

**Complexité** : 🟡 **Moyenne**

**Tests à Implémenter** :
1. Facettes catégorie (COUNT par cat_auto)
2. Facettes temporelles (COUNT par date_op)
3. Facettes combinées (COUNT par cat_auto + date_op)
4. Performance facettes (latence)
5. Validation résultats (cohérence)

**Script à créer** : `20_test_facettes.sh`

---

### 2.7 Tests de Pagination et Navigation (❌ MANQUANT)

**Contexte** : Inputs-clients mentionnent SCAN pour grandes volumétries

#### TC-MISS-13 : Tests de Pagination Complexe

**Description** :
- Pagination avec LIMIT + OFFSET
- Pagination avec token (paging_state)
- Navigation avant/arrière
- Performance pagination

**Complexité** : 🟡 **Moyenne**

**Tests à Implémenter** :
1. Pagination basique (LIMIT + OFFSET)
2. Pagination avec token (paging_state HCD)
3. Navigation avant/arrière (next/previous)
4. Performance pagination (latence selon offset)
5. Validation cohérence (pas de doublons, pas de manques)

**Script à créer** : `20_test_pagination.sh`

---

### 2.8 Tests de Cache et Optimisation (❌ MANQUANT)

**Contexte** : Inputs-clients mentionnent performance et optimisation

#### TC-MISS-14 : Tests de Cache d'Embeddings

**Description** :
- Cache des embeddings (éviter régénération)
- Cache des résultats de recherche
- Invalidation cache (stratégies)
- Performance avec/sans cache

**Complexité** : 🟡 **Moyenne**

**Tests à Implémenter** :
1. Cache embeddings (régénération vs réutilisation)
2. Cache résultats (même requête = résultats cachés)
3. Invalidation cache (TTL, manuel)
4. Performance avec cache (latence réduite)
5. Validation cohérence (cache vs source)

**Script à créer** : `20_test_cache.sh`

---

### 2.9 Tests de Suggestions et Autocomplétion (❌ MANQUANT)

**Contexte** : Inputs-IBM mentionnent recherche avancée

#### TC-MISS-15 : Tests de Suggestions/Autocomplétion

**Description** :
- Suggestions basées sur libellés existants
- Autocomplétion avec préfixes
- Suggestions avec scoring (pertinence)
- Performance suggestions

**Complexité** : 🟡 **Moyenne**

**Tests à Implémenter** :
1. Suggestions par préfixe (libelle_prefix)
2. Suggestions avec scoring (pertinence)
3. Autocomplétion (completion suggérée)
4. Performance suggestions (latence < 50ms)
5. Validation pertinence (suggestions pertinentes)

**Script à créer** : `20_test_suggestions.sh`

---

## 📊 PARTIE 3 : Matrice de Priorisation

### 3.1 Priorité 🔴 Critique (À Implémenter en Priorité)

| Test | Complexité | Impact | Effort | Priorité |
|------|------------|--------|--------|----------|
| **TC-MISS-01** | Migration Incrémentale | 🔴 Critique | 🔴 Élevé | **P1** |
| **TC-MISS-05** | Charge Concurrente | 🔴 Critique | 🔴 Élevé | **P1** |
| **TC-MISS-07** | Recherche Multi-Modèles Fusion | 🔴 Critique | 🟡 Moyen | **P1** |
| **TC-MISS-03** | Cohérence Transactionnelle | 🔴 Critique | 🟡 Moyen | **P1** |

**Justification** :
- Migration incrémentale : Core fonctionnalité HBase → HCD
- Charge concurrente : Validation production
- Recherche multi-modèles : Optimisation pertinence
- Cohérence transactionnelle : Intégrité données

---

### 3.2 Priorité 🟡 Haute (À Implémenter)

| Test | Complexité | Impact | Effort | Priorité |
|------|------------|--------|--------|----------|
| **TC-MISS-02** | Fenêtre Glissante Complexe | 🟡 Moyenne-Haute | 🟡 Moyen | **P2** |
| **TC-MISS-06** | Scalabilité | 🟡 Moyenne-Haute | 🟡 Moyen | **P2** |
| **TC-MISS-08** | Filtres Multiples | 🟡 Moyenne-Haute | 🟢 Faible | **P2** |
| **TC-MISS-04** | Contraintes Métier | 🟡 Moyenne | 🟡 Moyen | **P2** |
| **TC-MISS-11** | Agrégations | 🟡 Moyenne | 🟢 Faible | **P2** |

**Justification** :
- Fenêtre glissante : Export périodique
- Scalabilité : Validation volumes production
- Filtres multiples : Recherche avancée
- Contraintes métier : Intégrité données
- Agrégations : Analytics

---

### 3.3 Priorité 🟢 Moyenne (Optionnel)

| Test | Complexité | Impact | Effort | Priorité |
|------|------------|--------|--------|----------|
| **TC-MISS-09** | Résilience | 🟡 Moyenne | 🟡 Moyen | **P3** |
| **TC-MISS-12** | Facettes | 🟡 Moyenne | 🟢 Faible | **P3** |
| **TC-MISS-13** | Pagination | 🟡 Moyenne | 🟢 Faible | **P3** |
| **TC-MISS-14** | Cache | 🟡 Moyenne | 🟡 Moyen | **P3** |
| **TC-MISS-15** | Suggestions | 🟡 Moyenne | 🟡 Moyen | **P3** |
| **TC-MISS-10** | Failover | 🔴 Haute | 🔴 Élevé | **P3** (nécessite cluster) |

**Justification** :
- Résilience : Robustesse production
- Facettes : UX améliorée
- Pagination : Navigation grandes volumétries
- Cache : Optimisation performance
- Suggestions : UX améliorée
- Failover : Nécessite cluster (non applicable POC)

---

## 📋 PARTIE 4 : Détails des Tests Complexes Prioritaires

### TC-MISS-01 : Migration Incrémentale avec Validation (P1)

**Objectif** : Valider la migration incrémentale avec STARTROW/STOPROW équivalents

**Tests à Implémenter** :

1. **Export par Plages Précises** :
   - Export par code_si + contrat + date_op + numero_op
   - Validation plages non chevauchantes
   - Validation complétude (toutes les plages couvrent toutes les données)

2. **Validation Cohérence Source vs Export** :
   - Comptage source (HCD) vs export (Parquet)
   - Validation intégrité (pas de corruption)
   - Validation doublons (déduplication)

3. **Gestion Doublons** :
   - Détection doublons (même code_si + contrat + date_op + numero_op)
   - Déduplication automatique
   - Validation pas de perte de données

4. **Reprise Après Interruption** :
   - Checkpointing (sauvegarde état export)
   - Reprise depuis checkpoint
   - Validation cohérence après reprise

5. **Validation Multi-Tables** :
   - Cohérence operations_by_account vs meta-categories
   - Validation référentiel (pas de références orphelines)
   - Validation contraintes métier

**Script** : `20_test_migration_complexe.sh`

---

### TC-MISS-05 : Tests de Charge Concurrente (P1)

**Objectif** : Valider les performances sous charge concurrente

**Tests à Implémenter** :

1. **Charge Lecture** :
   - 100+ requêtes simultanées (recherche vectorielle)
   - Mesure latence (p50, p95, p99)
   - Mesure throughput (requêtes/seconde)
   - Détection goulots d'étranglement

2. **Charge Écriture** :
   - 100+ insertions simultanées
   - Mesure latence écriture
   - Mesure throughput écriture
   - Validation cohérence (pas de perte)

3. **Charge Mixte** :
   - 50% lecture, 50% écriture simultanées
   - Mesure latence mixte
   - Mesure throughput mixte
   - Validation cohérence (lectures cohérentes)

4. **Dégradation Performance** :
   - Mesure latence selon nombre de requêtes simultanées
   - Identification seuil de dégradation
   - Recommandations limites

**Script** : `20_test_charge_concurrente.sh`

---

### TC-MISS-07 : Recherche Multi-Modèles avec Fusion (P1)

**Objectif** : Valider la recherche avec plusieurs modèles simultanément et fusion des résultats

**Tests à Implémenter** :

1. **Recherche Multi-Modèles** :
   - Recherche avec ByteT5 + e5-large + Facturation simultanément
   - Comparaison résultats (pertinence, latence)
   - Identification meilleur modèle par requête

2. **Fusion Résultats** :
   - Déduplication (même libellé = un seul résultat)
   - Scoring combiné (moyenne pondérée des scores)
   - Ranking personnalisé (tri par score combiné)

3. **Fallback Automatique** :
   - Si modèle 1 échoue → modèle 2
   - Si modèle 2 échoue → modèle 3
   - Validation fallback (résultats toujours retournés)

4. **Comparaison Pertinence** :
   - Mono-modèle vs multi-modèles
   - Mesure amélioration pertinence
   - Recommandation stratégie

**Script** : `20_test_recherche_multi_modeles_fusion.sh`

---

### TC-MISS-03 : Cohérence Transactionnelle Multi-Tables (P1)

**Objectif** : Valider la cohérence entre plusieurs tables simultanément

**Tests à Implémenter** :

1. **Cohérence Référentielle** :
   - acceptation_client → operations_by_account (code_si + contrat existe)
   - opposition_categorisation → operations_by_account
   - historique_opposition → opposition_categorisation

2. **Cohérence Temporelle** :
   - Dates cohérentes (date_op <= date_valeur)
   - Dates acceptation <= dates opération
   - Dates historique cohérentes

3. **Cohérence Compteurs** :
   - feedback_par_libelle.count = SUM feedbacks pour libellé
   - feedback_par_ics.count = SUM feedbacks pour ICS
   - Validation compteurs atomiques

4. **Cohérence Historique** :
   - historique_opposition → opposition_categorisation (même no_pse)
   - Validation séquence historique (dates croissantes)
   - Validation pas de trous dans l'historique

5. **Cohérence Règles** :
   - cat_auto doit exister dans regles_personnalisees
   - Validation règles actives (actif = true)
   - Validation priorité règles

**Script** : `20_test_coherence_transactionnelle.sh`

---

## 📋 PARTIE 5 : Plan d'Implémentation

### Phase 1 : Tests Critiques (P1) - 4 Tests

1. ✅ **TC-MISS-01** : Migration Incrémentale avec Validation
2. ✅ **TC-MISS-05** : Tests de Charge Concurrente
3. ✅ **TC-MISS-07** : Recherche Multi-Modèles avec Fusion
4. ✅ **TC-MISS-03** : Cohérence Transactionnelle Multi-Tables

**Durée estimée** : 2-3 jours

---

### Phase 2 : Tests Haute Priorité (P2) - 5 Tests

1. ✅ **TC-MISS-02** : Fenêtre Glissante Complexe
2. ✅ **TC-MISS-06** : Scalabilité
3. ✅ **TC-MISS-08** : Filtres Multiples
4. ✅ **TC-MISS-04** : Contraintes Métier
5. ✅ **TC-MISS-11** : Agrégations

**Durée estimée** : 2-3 jours

---

### Phase 3 : Tests Optionnels (P3) - 6 Tests

1. ✅ **TC-MISS-09** : Résilience
2. ✅ **TC-MISS-12** : Facettes
3. ✅ **TC-MISS-13** : Pagination
4. ✅ **TC-MISS-14** : Cache
5. ✅ **TC-MISS-15** : Suggestions
6. ⚠️ **TC-MISS-10** : Failover (nécessite cluster)

**Durée estimée** : 2-3 jours

---

## ✅ Recommandation Finale

### Tests à Implémenter en Priorité

**Priorité P1 (Critique)** : **4 tests**
- Migration Incrémentale avec Validation
- Tests de Charge Concurrente
- Recherche Multi-Modèles avec Fusion
- Cohérence Transactionnelle Multi-Tables

**Priorité P2 (Haute)** : **5 tests**
- Fenêtre Glissante Complexe
- Scalabilité
- Filtres Multiples
- Contraintes Métier
- Agrégations

**Total** : **9 tests complexes prioritaires** à implémenter

---

**Date de génération** : 2025-11-30  
**Version** : 1.0

