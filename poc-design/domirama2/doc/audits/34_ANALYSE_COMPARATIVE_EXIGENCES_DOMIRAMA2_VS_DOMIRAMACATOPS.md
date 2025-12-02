# 🔍 Analyse Comparative : Exigences Spécifiques par POC

**Date** : 2025-12-01  
**Objectif** : Identifier les exigences spécifiques à `domirama2` qui n'existent pas dans `domiramaCatOps`, et vice-versa  
**Périmètre** : Analyse exhaustive des exigences E-01 à E-35

---

## 📋 Résumé Exécutif

| POC | Nombre Total Exigences | Exigences Spécifiques | Exigences Partagées |
|-----|------------------------|----------------------|---------------------|
| **domirama2** | 24 | **1** (E-24) | 23 |
| **domiramaCatOps** | 35 | **12** (E-08 à E-14, E-20, E-25, E-26, E-35) | 23 |
| **TOTAL UNIQUE** | **36** | **13** | **23** |

**Conclusion** : `domiramaCatOps` couvre **12 exigences supplémentaires** liées à la table `domirama-meta-categories` et à des innovations avancées. `domirama2` possède **1 exigence spécifique** (Multi-Version et Time Travel explicite).

---

## 🎯 PARTIE 1 : EXIGENCES SPÉCIFIQUES À `domirama2`

### EXIGENCE E-24 : Multi-Version et Time Travel (Stratégie Explicite)

#### Description

**Exigence** :

- Stratégie multi-version explicite (batch vs client)
- Time travel (récupération données à une date donnée)
- Aucune correction client perdue
- Démonstration explicite de la logique de priorité

#### Pourquoi Spécifique à `domirama2` ?

**Dans `domirama2`** :

- ✅ **Exigence E-24 dédiée** : Documentée comme exigence à part entière
- ✅ **Script dédié** : `scripts/26_test_multi_version_time_travel.sh`
- ✅ **Démonstration explicite** : Tests de time travel, récupération historique
- ✅ **Documentation détaillée** : Stratégie multi-version expliquée en détail

**Dans `domiramaCatOps`** :

- ⚠️ **Intégré dans E-02/E-03** : Multi-version mentionné dans les exigences batch/temps réel
- ⚠️ **Pas d'exigence dédiée** : Pas d'exigence E-24 équivalente
- ⚠️ **Pas de script dédié** : Pas de script `26_test_multi_version_time_travel.sh`
- ⚠️ **Documentation implicite** : Stratégie multi-version présente mais moins explicite

#### Impact

**Valeur Ajoutée `domirama2`** :

- ✅ **Démonstration pédagogique** : Time travel explicite facilite la compréhension
- ✅ **Validation robuste** : Tests dédiés garantissent la non-perte de corrections
- ✅ **Documentation claire** : Stratégie multi-version documentée séparément

**Recommandation** :

- `domiramaCatOps` pourrait bénéficier d'une exigence E-24 dédiée pour aligner la documentation

---

## 🎯 PARTIE 2 : EXIGENCES SPÉCIFIQUES À `domiramaCatOps`

### EXIGENCES E-08 à E-14 : Table `domirama-meta-categories`

#### Description

**Exigences** :

- **E-08** : Acceptation et Opposition Client
- **E-09** : Historique des Oppositions (VERSIONS => '50')
- **E-10** : Feedbacks par Libellé (Compteurs Atomiques)
- **E-11** : Feedbacks par ICS (Compteurs)
- **E-12** : Règles Personnalisées Client
- **E-13** : Décisions Salaires
- **E-14** : Cohérence Multi-Tables

#### Pourquoi Spécifiques à `domiramaCatOps` ?

**Dans `domiramaCatOps`** :

- ✅ **7 tables dédiées** : `acceptation_client`, `opposition_categorisation`, `historique_opposition`, `feedback_par_libelle`, `feedback_par_ics`, `regles_personnalisees`, `decisions_salaires`
- ✅ **Scripts dédiés** : `scripts/03_setup_meta_categories_tables.sh`, `scripts/09_test_acceptation_opposition.sh`, etc.
- ✅ **Documentation complète** : Chaque exigence documentée avec schémas CQL et tests

**Dans `domirama2`** :

- ❌ **Pas de table meta-categories** : Focus exclusif sur table `domirama`
- ❌ **Pas d'exigences équivalentes** : Pas d'exigences E-08 à E-14
- ❌ **Périmètre différent** : `domirama2` ne couvre que la table `domirama`

#### Impact

**Valeur Ajoutée `domiramaCatOps`** :

- ✅ **Couverture complète** : Toutes les fonctionnalités de catégorisation couvertes
- ✅ **Démonstration métier** : Acceptation, opposition, règles personnalisées démontrées
- ✅ **Feedbacks et statistiques** : Compteurs atomiques, distribution des catégories
- ✅ **Historique illimité** : Amélioration vs HBase (VERSIONS='50' → historique illimité)

**Recommandation** :

- `domirama2` pourrait être étendu pour couvrir `domirama-meta-categories` si nécessaire

---

### EXIGENCE E-20 : Ingestion Temps Réel Kafka → Spark Streaming

#### Description

**Exigence** :

- Ingestion temps réel via Kafka
- Spark Structured Streaming
- Checkpointing pour reprise
- Latence faible (< 1 seconde)

#### Pourquoi Spécifique à `domiramaCatOps` ?

**Dans `domiramaCatOps`** :

- ✅ **Exigence E-20 dédiée** : Documentée comme exigence à part entière
- ✅ **Script dédié** : `scripts/27_demo_kafka_streaming.sh`
- ✅ **Démonstration complète** : Kafka + Spark Streaming + Checkpointing

**Dans `domirama2`** :

- ⚠️ **Pas d'exigence équivalente** : Pas d'exigence E-20
- ⚠️ **Pas de script Kafka** : Pas de script `27_demo_kafka_streaming.sh`
- ⚠️ **Ingestion temps réel différente** : E-03 couvre corrections client via API, pas Kafka

#### Impact

**Valeur Ajoutée `domiramaCatOps`** :

- ✅ **Architecture moderne** : Kafka + Spark Streaming pour ingestion temps réel
- ✅ **Scalabilité** : Support de flux de données haute volumétrie
- ✅ **Résilience** : Checkpointing pour reprise après échec

**Recommandation** :

- `domirama2` pourrait bénéficier d'une démonstration Kafka si nécessaire pour des cas d'usage temps réel haute volumétrie

---

### EXIGENCE E-25 : Équivalent VERSIONS => '50' (Table d'Historique)

#### Description

**Exigence** :

- Équivalent HBase `VERSIONS => '50'` (limite 50 versions)
- Table `historique_opposition` (historique illimité)
- Traçabilité complète des changements

#### Pourquoi Spécifique à `domiramaCatOps` ?

**Dans `domiramaCatOps`** :

- ✅ **Exigence E-25 dédiée** : Documentée comme pattern HBase équivalent
- ✅ **Table dédiée** : `historique_opposition` avec clustering key sur timestamp
- ✅ **Amélioration vs HBase** : Historique illimité (vs 50 versions max)

**Dans `domirama2`** :

- ❌ **Pas d'exigence équivalente** : Pas d'exigence E-25
- ❌ **Pas de table historique** : Pas de besoin (pas de table meta-categories)
- ❌ **Périmètre différent** : `domirama2` ne couvre pas les oppositions

#### Impact

**Valeur Ajoutée `domiramaCatOps`** :

- ✅ **Amélioration fonctionnelle** : Historique illimité vs 50 versions HBase
- ✅ **Traçabilité complète** : Chaque changement horodaté
- ✅ **Requêtes efficaces** : Accès direct par date (clustering key)

---

### EXIGENCE E-26 : Équivalent INCREMENT Atomique (Type Counter)

#### Description

**Exigence** :

- Équivalent HBase `INCREMENT` atomique
- Type `COUNTER` natif HCD
- Atomicité garantie pour compteurs

#### Pourquoi Spécifique à `domiramaCatOps` ?

**Dans `domiramaCatOps`** :

- ✅ **Exigence E-26 dédiée** : Documentée comme pattern HBase équivalent
- ✅ **Tables COUNTER** : `feedback_par_libelle`, `feedback_par_ics` avec type `COUNTER`
- ✅ **Démonstration** : Tests d'atomicité, incréments concurrents

**Dans `domirama2`** :

- ❌ **Pas d'exigence équivalente** : Pas d'exigence E-26
- ❌ **Pas de tables COUNTER** : Pas de besoin (pas de feedbacks)
- ❌ **Périmètre différent** : `domirama2` ne couvre pas les feedbacks

#### Impact

**Valeur Ajoutée `domiramaCatOps`** :

- ✅ **Atomicité native** : Type `COUNTER` garantit l'atomicité
- ✅ **Performance** : Pas de locks explicites nécessaires
- ✅ **Simplicité** : Syntaxe CQL simple pour incréments

---

### EXIGENCE E-35 : Multi-Modèles Embeddings (Innovation)

#### Description

**Exigence** :

- Support multi-modèles embeddings (innovation)
- ByteT5, e5-large, invoice
- Comparaison et sélection intelligente

#### Pourquoi Spécifique à `domiramaCatOps` ?

**Dans `domiramaCatOps`** :

- ✅ **Exigence E-35 dédiée** : Documentée comme innovation
- ✅ **3 colonnes embeddings** : `libelle_embedding` (ByteT5), `libelle_embedding_e5` (e5-large), `libelle_embedding_invoice` (invoice)
- ✅ **Scripts dédiés** : `scripts/17_add_e5_embedding_column.sh`, `scripts/18_add_invoice_embedding_column.sh`, `scripts/19_test_embeddings_comparison.sh`
- ✅ **Comparaison** : Tests de comparaison entre modèles

**Dans `domirama2`** :

- ⚠️ **1 modèle uniquement** : ByteT5 seulement (E-08)
- ⚠️ **Pas d'exigence E-35** : Pas de multi-modèles
- ⚠️ **Pas de comparaison** : Pas de script de comparaison entre modèles

#### Impact

**Valeur Ajoutée `domiramaCatOps`** :

- ✅ **Flexibilité** : Choix du meilleur modèle selon cas d'usage
- ✅ **Optimisation** : ByteT5 pour typos, e5-large pour sémantique, invoice pour facturation
- ✅ **Innovation** : Dépassement des attentes (120% conformité)

**Recommandation** :

- `domirama2` pourrait bénéficier d'une extension multi-modèles si nécessaire

---

## 🎯 PARTIE 3 : EXIGENCES PARTAGÉES (23 Exigences)

### Tableau Récapitulatif

| ID | Exigence | domirama2 | domiramaCatOps | Statut |
|----|----------|-----------|----------------|--------|
| **E-01** | Stockage des Opérations | ✅ | ✅ | Partagé |
| **E-02** | Écriture Batch (MapReduce bulkLoad) | ✅ | ✅ | Partagé |
| **E-03** | Écriture Temps Réel (Corrections Client) | ✅ | ✅ | Partagé |
| **E-04** | Lecture et Recherche | ✅ | ✅ | Partagé |
| **E-05** | Export Incrémental (TIMERANGE) | ✅ | ✅ | Partagé |
| **E-06** | TTL et Purge Automatique | ✅ | ✅ | Partagé |
| **E-07** | Recherche Full-Text avec Analyzers Lucene | ✅ | ✅ | Partagé |
| **E-08** | Recherche Vectorielle (ByteT5) | ✅ | ✅ | Partagé |
| **E-09** | Recherche Hybride (Full-Text + Vector) | ✅ | ✅ | Partagé |
| **E-10** | Data API (REST/GraphQL) | ✅ | ✅ | Partagé |
| **E-11** | Ingestion Batch Spark | ✅ | ✅ | Partagé |
| **E-12** | Export Incrémental Parquet | ✅ | ✅ | Partagé |
| **E-13** | Indexation SAI Complète | ✅ | ✅ | Partagé |
| **E-14** | Équivalent RowKey | ✅ | ✅ | Partagé |
| **E-15** | Équivalent Column Family | ✅ | ✅ | Partagé |
| **E-16** | Équivalent Colonnes Dynamiques | ✅ | ✅ | Partagé |
| **E-17** | Équivalent BLOOMFILTER | ✅ | ✅ | Partagé |
| **E-18** | Équivalent REPLICATION_SCOPE | ✅ | ✅ | Partagé |
| **E-19** | Équivalent FullScan + TIMERANGE | ✅ | ✅ | Partagé |
| **E-20** | Performance Lecture | ✅ | ✅ | Partagé |
| **E-21** | Performance Écriture | ✅ | ✅ | Partagé |
| **E-22** | Charge Concurrente | ✅ | ✅ | Partagé |
| **E-23** | Recherche Sémantique (Innovation) | ✅ | ✅ | Partagé |

**Total Partagé** : **23 exigences**

---

## 📊 PARTIE 4 : ANALYSE PAR CATÉGORIE

### 4.1 Exigences Inputs-Clients

| Catégorie | domirama2 | domiramaCatOps | Différence |
|-----------|-----------|----------------|------------|
| **Table `domirama`** | 6 exigences (E-01 à E-06) | 7 exigences (E-01 à E-07) | +1 (E-07 TTL dédié) |
| **Table `domirama-meta-categories`** | 0 exigence | 7 exigences (E-08 à E-14) | +7 (spécifique CatOps) |

**Conclusion** : `domiramaCatOps` couvre **7 exigences supplémentaires** liées à `domirama-meta-categories`.

---

### 4.2 Exigences Inputs-IBM

| Catégorie | domirama2 | domiramaCatOps | Différence |
|-----------|-----------|----------------|------------|
| **Recommandations Techniques** | 6 exigences (E-07 à E-12) | 8 exigences (E-15 à E-22) | +2 (E-20 Kafka, E-22 Indexation) |

**Conclusion** : `domiramaCatOps` couvre **2 exigences supplémentaires** (Kafka Streaming, Indexation SAI complète).

---

### 4.3 Patterns HBase Équivalents

| Catégorie | domirama2 | domiramaCatOps | Différence |
|-----------|-----------|----------------|------------|
| **Patterns HBase** | 6 exigences (E-13 à E-18) | 8 exigences (E-23 à E-30) | +2 (E-25 VERSIONS, E-26 INCREMENT) |

**Conclusion** : `domiramaCatOps` couvre **2 patterns supplémentaires** (VERSIONS, INCREMENT) liés à `domirama-meta-categories`.

---

### 4.4 Performance et Scalabilité

| Catégorie | domirama2 | domiramaCatOps | Différence |
|-----------|-----------|----------------|------------|
| **Performance** | 3 exigences (E-19 à E-21) | 3 exigences (E-31 à E-33) | 0 (identique) |

**Conclusion** : **Aucune différence** - Les deux POC couvrent les mêmes exigences de performance.

---

### 4.5 Modernisation et Innovation

| Catégorie | domirama2 | domiramaCatOps | Différence |
|-----------|-----------|----------------|------------|
| **Innovation** | 2 exigences (E-22, E-24) | 2 exigences (E-34, E-35) | +1 (E-35 Multi-Modèles) |

**Conclusion** : `domiramaCatOps` couvre **1 innovation supplémentaire** (Multi-Modèles Embeddings).

---

## 🎯 PARTIE 5 : RECOMMANDATIONS

### 5.1 Pour `domirama2`

**Recommandations** :

1. ✅ **Conserver E-24** : Multi-Version et Time Travel explicite est une force pédagogique
2. ⚠️ **Optionnel** : Ajouter support `domirama-meta-categories` si besoin métier
3. ⚠️ **Optionnel** : Ajouter démonstration Kafka si besoin temps réel haute volumétrie
4. ⚠️ **Optionnel** : Ajouter multi-modèles embeddings si besoin optimisation pertinence

**Priorité** : **Faible** - `domirama2` est déjà complet pour son périmètre (table `domirama` uniquement).

---

### 5.2 Pour `domiramaCatOps`

**Recommandations** :

1. ✅ **Conserver toutes les exigences** : Couverture complète est une force
2. ⚠️ **Optionnel** : Ajouter E-24 dédiée pour aligner avec `domirama2` (pédagogie)
3. ✅ **Maintenir innovation** : Multi-Modèles Embeddings est une différenciation

**Priorité** : **Très faible** - `domiramaCatOps` est déjà complet et supérieur en couverture.

---

## ✅ CONCLUSION

### Résumé des Différences

| Aspect | domirama2 | domiramaCatOps |
|--------|-----------|----------------|
| **Périmètre** | Table `domirama` uniquement | Tables `domirama` + `domirama-meta-categories` |
| **Exigences Total** | 24 | 35 |
| **Exigences Spécifiques** | 1 (E-24) | 12 (E-08 à E-14, E-20, E-25, E-26, E-35) |
| **Exigences Partagées** | 23 | 23 |
| **Forces** | Time Travel explicite | Couverture complète, Multi-Modèles, Kafka |
| **Faiblesses** | Périmètre limité | Time Travel moins explicite |

### Recommandation Globale

**Les deux POC sont complémentaires** :

- **`domirama2`** : Excellent pour démonstration table `domirama` avec focus pédagogique
- **`domiramaCatOps`** : Excellent pour démonstration complète avec toutes les fonctionnalités métier

**Aucune action urgente nécessaire** - Les deux POC répondent à leurs objectifs respectifs.

---

**Date** : 2025-12-01  
**Version** : 1.0  
**Statut** : ✅ **Analyse complète**
