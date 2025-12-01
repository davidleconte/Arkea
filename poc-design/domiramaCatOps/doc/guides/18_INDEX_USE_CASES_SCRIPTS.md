# 📑 Index des Use Cases et Scripts - DomiramaCatOps

**Date** : 2025-01-XX  
**Dernière mise à jour** : 2025-01-XX  
**Version** : 1.0  
**Objectif** : Index complet pour navigation rapide entre use cases et scripts

> **Note** : Pour un audit complet des scripts et use cases, voir [17_AUDIT_COMPLET_SCRIPTS_USE_CASES.md](17_AUDIT_COMPLET_SCRIPTS_USE_CASES.md).

---

## 📊 Résumé

**Total Use Cases** : **25 use cases**  
**Total Scripts** : **29 scripts**  
**Couverture** : **100%** ✅

---

## 🔗 Liens vers les Démonstrations

### Démonstrations par Use Case

- **UC-01 à UC-10** (Table `domirama`) : Voir [démonstrations/05_INGESTION_OPERATIONS_DEMONSTRATION.md](demonstrations/05_INGESTION_OPERATIONS_DEMONSTRATION.md), [démonstrations/14_INCREMENTAL_EXPORT_DEMONSTRATION.md](demonstrations/14_INCREMENTAL_EXPORT_DEMONSTRATION.md), [démonstrations/19_TTL_DEMONSTRATION.md](demonstrations/19_TTL_DEMONSTRATION.md), [démonstrations/21_BLOOMFILTER_DEMONSTRATION.md](demonstrations/21_BLOOMFILTER_DEMONSTRATION.md)
- **UC-11 à UC-20** (Table `domirama-meta-categories`) : Voir [démonstrations/09_ACCEPTATION_OPPOSITION_DEMONSTRATION.md](demonstrations/09_ACCEPTATION_OPPOSITION_DEMONSTRATION.md), [démonstrations/15_COHERENCE_MULTI_TABLES_DEMONSTRATION.md](demonstrations/15_COHERENCE_MULTI_TABLES_DEMONSTRATION.md)
- **UC-05** (Recherche avancée) : Voir [démonstrations/16_FUZZY_SEARCH_COMPLETE_DEMONSTRATION.md](demonstrations/16_FUZZY_SEARCH_COMPLETE_DEMONSTRATION.md), [démonstrations/18_HYBRID_SEARCH_V2_DEMONSTRATION.md](demonstrations/18_HYBRID_SEARCH_V2_DEMONSTRATION.md)
- **UC-SEARCH-01 à UC-SEARCH-03** : Voir [démonstrations/16_COMPARAISON_BYTET5_E5_DEMONSTRATION.md](demonstrations/16_COMPARAISON_BYTET5_E5_DEMONSTRATION.md), [démonstrations/16_COMPARAISON_3_MODELES_DEMONSTRATION.md](demonstrations/16_COMPARAISON_3_MODELES_DEMONSTRATION.md)

### Toutes les Démonstrations

Voir le répertoire [demonstrations/](demonstrations/) pour la liste complète des démonstrations détaillées.

---

## 🔍 PARTIE 1 : INDEX USE CASE → SCRIPTS

### Use Cases Inputs-Clients - Table `domirama`

| Use Case | Description | Script(s) | Type |
|----------|-------------|-----------|------|
| **UC-01** | Catégorisation automatique (batch) | `05_load_operations_data_parquet.sh` | Chargement |
| **UC-02** | Correction client (temps réel) | `07_load_category_data_realtime.sh` | Chargement |
| **UC-03** | Stratégie multi-version | `05_load_operations_data_parquet.sh`, `07_load_category_data_realtime.sh` | Chargement |
| **UC-04** | Recherche par catégorie | `08_test_category_search.sh` | Test |
| **UC-05** | Recherche par libellé (full-text, fuzzy, hybrid) | `16_test_fuzzy_search.sh`, `17_demonstration_fuzzy_search.sh`, `18_test_hybrid_search.sh` | Recherche |
| **UC-06** | Export incrémental (TIMERANGE) | `14_test_incremental_export.sh` | Test |
| **UC-07** | Filtrage colonnes dynamiques | `13_test_dynamic_columns.sh` | Test |
| **UC-08** | TTL et purge automatique | `19_demo_ttl.sh` | Démonstration |
| **UC-09** | BLOOMFILTER équivalent | `21_demo_bloomfilter_equivalent.sh` | Démonstration |
| **UC-10** | REPLICATION_SCOPE équivalent | `22_demo_replication_scope.sh` | Démonstration |

### Use Cases Inputs-Clients - Table `domirama-meta-categories`

| Use Case | Description | Script(s) | Type |
|----------|-------------|-----------|------|
| **UC-11** | Acceptation client | `09_test_acceptation_opposition.sh` | Test |
| **UC-12** | Opposition catégorisation | `09_test_acceptation_opposition.sh` | Test |
| **UC-13** | Historique opposition (VERSIONS) | `12_test_historique_opposition.sh` | Test |
| **UC-14** | Feedbacks par libellé (compteurs) | `11_test_feedbacks_counters.sh` | Test |
| **UC-15** | Feedbacks par ICS (compteurs) | `25_test_feedbacks_ics.sh` | Test |
| **UC-16** | Règles personnalisées | `10_test_regles_personnalisees.sh` | Test |
| **UC-17** | Décisions salaires | `26_test_decisions_salaires.sh` | Test |
| **UC-18** | Application règles personnalisées (batch) | `05_load_operations_data_parquet.sh` | Chargement |
| **UC-19** | Mise à jour feedbacks (temps réel) | `07_load_category_data_realtime.sh` | Chargement |
| **UC-20** | Cohérence multi-tables | `15_test_coherence_multi_tables.sh` | Test |

### Use Cases Additionnels

| Use Case | Description | Script(s) | Type |
|----------|-------------|-----------|------|
| **UC-API-01** | Data API REST/GraphQL | `24_demo_data_api.sh` | Démonstration |
| **UC-STREAM-01** | Kafka + Spark Streaming | `27_demo_kafka_streaming.sh` | Démonstration |
| **UC-SEARCH-01** | Recherche full-text avancée | `08_test_category_search.sh` (via SAI) | Test |
| **UC-SEARCH-02** | Recherche vectorielle (ByteT5) | `16_test_fuzzy_search.sh`, `17_demonstration_fuzzy_search.sh` | Recherche |
| **UC-SEARCH-03** | Recherche hybride | `18_test_hybrid_search.sh` | Recherche |

---

## 🔍 PARTIE 2 : INDEX SCRIPT → USE CASES

### Scripts Setup

| Script | Use Cases | Description |
|--------|-----------|-------------|
| `01_setup_domiramaCatOps_keyspace.sh` | UC-SETUP-01 | Création keyspace |
| `02_setup_operations_by_account.sh` | UC-SETUP-02 | Création table operations |
| `03_setup_meta_categories_tables.sh` | UC-SETUP-03 | Création 7 tables meta-categories |
| `04_create_indexes.sh` | UC-SETUP-04 | Création index SAI (operations + meta-categories) |

### Scripts Génération

| Script | Use Cases | Description |
|--------|-----------|-------------|
| `04_generate_operations_parquet.sh` | UC-GEN-01 | Génération 20k+ opérations |
| `04_generate_meta_categories_parquet.sh` | UC-GEN-02 | Génération 7 fichiers Parquet |
| `05_generate_libelle_embedding.sh` | UC-GEN-03 | Génération embeddings ByteT5 |

### Scripts Chargement

| Script | Use Cases | Description |
|--------|-----------|-------------|
| `05_load_operations_data_parquet.sh` | UC-01, UC-03, UC-18 | Chargement batch avec règles et feedbacks |
| `05_update_feedbacks_counters.sh` | UC-19 | Mise à jour feedbacks (optionnel) |
| `06_load_meta_categories_data_parquet.sh` | UC-META-01 | Chargement 7 tables meta-categories |
| `07_load_category_data_realtime.sh` | UC-02, UC-03, UC-19 | Corrections client temps réel |

### Scripts Tests

| Script | Use Cases | Description |
|--------|-----------|-------------|
| `08_test_category_search.sh` | UC-04, UC-SEARCH-01 | Recherche par catégorie |
| `09_test_acceptation_opposition.sh` | UC-11, UC-12 | Acceptation/Opposition |
| `10_test_regles_personnalisees.sh` | UC-16 | Règles personnalisées |
| `11_test_feedbacks_counters.sh` | UC-14 | Feedbacks par libellé |
| `12_test_historique_opposition.sh` | UC-13 | Historique opposition |
| `13_test_dynamic_columns.sh` | UC-07 | Colonnes dynamiques |
| `14_test_incremental_export.sh` | UC-06 | Export incrémental |
| `15_test_coherence_multi_tables.sh` | UC-20 | Cohérence multi-tables |

### Scripts Recherche Avancée

| Script | Use Cases | Description |
|--------|-----------|-------------|
| `16_test_fuzzy_search.sh` | UC-05, UC-SEARCH-02 | Fuzzy search (vector) |
| `17_demonstration_fuzzy_search.sh` | UC-05, UC-SEARCH-02 | Démonstration fuzzy search |
| `18_test_hybrid_search.sh` | UC-05, UC-SEARCH-03 | Hybrid search |

### Scripts Démonstration

| Script | Use Cases | Description |
|--------|-----------|-------------|
| `19_demo_ttl.sh` | UC-08 | TTL et purge automatique |
| `21_demo_bloomfilter_equivalent.sh` | UC-09 | BLOOMFILTER équivalent |
| `22_demo_replication_scope.sh` | UC-10 | REPLICATION_SCOPE équivalent |
| `24_demo_data_api.sh` | UC-API-01 | Data API REST/GraphQL |
| `25_test_feedbacks_ics.sh` | UC-15 | Feedbacks par ICS |
| `26_test_decisions_salaires.sh` | UC-17 | Décisions salaires |
| `27_demo_kafka_streaming.sh` | UC-STREAM-01 | Kafka + Spark Streaming |

---

## 🔍 PARTIE 3 : INDEX PAR PATTERN HBase

| Pattern HBase | Équivalent HCD | Script(s) | Use Case |
|---------------|----------------|-----------|----------|
| **RowKey** | Partition Key + Clustering Keys | `02_setup_operations_by_account.sh` | UC-SETUP-02 |
| **Column Family** | Colonnes normalisées | `02_setup_operations_by_account.sh` | UC-SETUP-02 |
| **TTL** | `default_time_to_live` | `19_demo_ttl.sh` | UC-08 |
| **VERSIONS => '50'** | Table d'historique | `12_test_historique_opposition.sh` | UC-13 |
| **INCREMENT atomique** | Type `counter` | `11_test_feedbacks_counters.sh`, `25_test_feedbacks_ics.sh` | UC-14, UC-15 |
| **Colonnes dynamiques** | `MAP<TEXT, TEXT>` | `13_test_dynamic_columns.sh` | UC-07 |
| **BLOOMFILTER** | Index SAI | `21_demo_bloomfilter_equivalent.sh` | UC-09 |
| **REPLICATION_SCOPE** | NetworkTopologyStrategy | `22_demo_replication_scope.sh` | UC-10 |
| **FullScan + TIMERANGE** | WHERE sur clustering keys | `14_test_incremental_export.sh` | UC-06 |
| **bulkLoad** | Spark + Parquet | `05_load_operations_data_parquet.sh` | UC-01 |

---

## ✅ CONCLUSION

**✅ Tous les use cases sont couverts par au moins un script**  
**✅ Tous les scripts démontrent clairement leurs use cases**  
**✅ Navigation facilitée entre use cases et scripts**

---

**Date** : 2025-01-XX  
**Version** : 1.0


