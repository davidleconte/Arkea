# 🎯 POC DomiramaCatOps : Migration HBase → HCD - Catégorisation des Opérations

**Date** : 2024-11-27  
**Projet** : Catégorisation des Opérations  
**Table HBase** : `B997X04:domirama` (Column Family `category`)  
**Objectif** : Démontrer la faisabilité de la migration de HBase vers DataStax HCD  
**Méthodologie** : Même approche que Domirama2

---

## 📋 Vue d'Ensemble

Ce POC démontre la migration de la table `B997X04:domirama` avec la Column Family `category` de HBase vers DataStax Hyper-Converged Database (HCD).

**Caractéristiques principales** :
- Extension du projet Domirama pour catégorisation automatique
- **Deux tables HBase sources** :
  - `B997X04:domirama` (Column Family `category`)
  - `B997X04:domirama-meta-categories` (7 "KeySpaces" logiques)
- Données Thrift encodées en binaire
- Colonnes dynamiques pour filtrage
- Stratégie multi-version (batch vs client)
- Compteurs atomiques (INCREMENT)
- TTL 10 ans
- BLOOMFILTER ROWCOL
- REPLICATION_SCOPE 1
- **Format source** : Parquet uniquement

---

## 📁 Structure du Projet

```
domiramaCatOps/
├── README.md                    # Ce fichier
├── doc/
│   ├── 00_ANALYSE_POC_DOMIRAMA_CAT_OPS.md  # Analyse MECE complète
│   ├── templates/               # Templates pour scripts didactiques
│   └── demonstrations/          # Rapports auto-générés
├── schemas/
│   └── *.cql                   # Schémas CQL (numérotés)
├── scripts/
│   └── *.sh                    # Scripts shell (numérotés)
└── data/                        # Données de test (si nécessaire)
```

---

## 🎯 Objectifs du POC

### Objectifs Fonctionnels

1. ✅ **Configuration et Schéma**
   - Création du keyspace et de la table
   - Colonnes de catégorisation
   - Key design conforme HBase

2. ✅ **Format de Stockage**
   - Données Thrift binaires (BLOB)
   - Colonnes dynamiques (MAP)

3. ✅ **Opérations d'Écriture**
   - Écriture batch (Spark)
   - Écriture temps réel (Data API/CQL)
   - Stratégie multi-version

4. ✅ **Opérations de Lecture**
   - Lecture temps réel (SELECT + SAI)
   - Lecture batch (export incrémental)
   - Recherche par catégorie

5. ✅ **Fonctionnalités Spécifiques**
   - TTL automatique
   - Temporalité (multi-version)
   - BLOOMFILTER équivalent
   - REPLICATION_SCOPE équivalent

### Objectifs Techniques

- ✅ Performance équivalente ou meilleure
- ✅ Compatibilité avec applications existantes
- ✅ Migration progressive possible
- ✅ Documentation complète

---

## 🚀 Guide d'Exécution

### Prérequis

- DataStax HCD 1.2 installé et démarré
- Spark 3.5.1 configuré
- `spark-cassandra-connector` installé
- Kafka (si nécessaire pour ingestion temps réel)
- Python 3.x (pour scripts de démonstration)

### Ordre d'Exécution

1. **Setup** :
   ```bash
   ./scripts/01_setup_domiramaCatOps_keyspace.sh      # Création keyspace
   ./scripts/02_setup_operations_by_account.sh        # Création table operations_by_account
   ./scripts/03_setup_meta_categories_tables.sh       # Création 7 tables meta-categories
   ./scripts/04_create_indexes.sh                     # Création index SAI
   ```

2. **Génération des Données** :
   ```bash
   ./scripts/04_generate_operations_parquet.sh        # Génération données operations (20k+ lignes)
   ./scripts/04_generate_meta_categories_parquet.sh   # Génération données meta-categories
   ```

3. **Ingestion** :
   ```bash
   ./scripts/05_load_operations_data_parquet.sh        # Chargement batch operations
   ./scripts/05_generate_libelle_embedding.sh          # Génération embeddings ByteT5
   ./scripts/05_update_feedbacks_counters.sh          # Mise à jour compteurs feedbacks
   ./scripts/06_load_meta_categories_data_parquet.sh  # Chargement batch meta-categories
   ./scripts/07_load_category_data_realtime.sh        # Chargement temps réel (corrections client)
   ```

4. **Tests Fonctionnels** :
   ```bash
   ./scripts/08_test_category_search.sh                # Tests recherche par catégorie
   ./scripts/09_test_acceptation_opposition.sh        # Tests acceptation/opposition
   ./scripts/10_test_regles_personnalisees.sh         # Tests règles personnalisées
   ./scripts/11_test_feedbacks_counters.sh            # Tests compteurs atomiques
   ./scripts/12_test_historique_opposition.sh         # Tests historique opposition
   ./scripts/13_test_dynamic_columns.sh               # Tests colonnes dynamiques
   ./scripts/14_test_incremental_export.sh            # Tests export incrémental
   ./scripts/15_test_coherence_multi_tables.sh         # Tests cohérence multi-tables
   ```

5. **Recherche Avancée** (Conforme Domirama2) :
   ```bash
   ./scripts/16_test_fuzzy_search.sh                  # Tests fuzzy search (vector)
   ./scripts/17_demonstration_fuzzy_search.sh        # Démonstration fuzzy search
   ./scripts/18_test_hybrid_search.sh                # Tests hybrid search (full-text + vector)
   ```

6. **Fonctionnalités Spécifiques** (À créer) :
   ```bash
   ./scripts/19_demo_ttl.sh                           # Démonstration TTL
   ./scripts/20_demo_multi_version.sh                 # Démonstration multi-version
   ./scripts/21_demo_bloomfilter_equivalent.sh       # Démonstration BLOOMFILTER équivalent
   ./scripts/22_demo_replication_scope.sh             # Démonstration REPLICATION_SCOPE
   ```

7. **Migration** (À créer) :
   ```bash
   ./scripts/23_migrate_hbase_to_hcd.sh               # Migration complète
   ./scripts/24_validate_migration.sh                 # Validation migration
   ```

---

## 📊 Statut du POC

**Phase actuelle** : 🔨 **Développement et Tests**

- ✅ Analyse complète des besoins (MECE)
- ✅ Analyse des deux tables HBase
- ✅ Data model HCD complet (8 tables)
- ✅ **Recherche avancée intégrée** (Full-Text, Vector, Hybrid, Fuzzy, N-Gram - conforme Domirama2)
- ✅ Structure du projet créée
- ✅ Impacts de la deuxième table analysés
- ✅ Schémas CQL créés (4 fichiers - avec colonnes recherche avancée)
- ✅ Scripts de setup créés (01, 02, 03, 04)
- ✅ Scripts de génération données créés (04_generate_*.sh)
- ✅ Scripts d'ingestion créés (05, 06, 07)
- ✅ Scripts de test fonctionnels créés (09, 10, 11, 12, 15)
- ⏳ Scripts de test manquants (08, 13, 14)
- ⏳ Scripts de recherche avancée (16, 17, 18)
- ⏳ Scripts fonctionnalités spécifiques (19-22)
- ⏳ Scripts migration (23, 24)
- ⏳ Exécution et validation complète

---

## 📚 Documentation

### Documents Principaux

1. **`doc/00_ANALYSE_POC_DOMIRAMA_CAT_OPS.md`**
   - Analyse MECE complète
   - Besoins à démontrer
   - Plan d'action
   - Implications et défis

2. **`doc/01_README.md`** (à créer)
   - Guide détaillé d'utilisation
   - Exemples d'utilisation
   - Troubleshooting

3. **`doc/02_GAPS_ANALYSIS.md`** (à créer)
   - Analyse des gaps fonctionnels
   - Comparaison HBase vs HCD
   - Statut de chaque fonctionnalité

4. **`doc/03_DEMONSTRATION_COMPLETE.md`** (à créer)
   - Documentation complète de toutes les démonstrations
   - Résultats
   - Validations

### Rapports Auto-Générés

Les scripts didactiques génèrent automatiquement des rapports dans `doc/demonstrations/` :
- `XX_DEMONSTRATION_NAME.md` : Rapport détaillé de chaque démonstration

---

## 🔗 Références

### Inputs-Clients

- **"Etat de l'art HBase chez Arkéa.pdf"** : Section "2. Catégorisation des Opérations"
- **groupe_2025-11-25-110250.zip** : Archives des projets catégorisation

### Inputs-IBM

- **PROPOSITION_MECE_MIGRATION_HBASE_HCD.md** : Section "Refonte de domirama-meta-categories"

### Projets Similaires

- **Domirama2** : POC de migration de la table Domirama principale
  - Structure similaire
  - Méthodologie identique
  - Référence pour ce POC

---

## 📝 Notes Importantes

### Différences avec Domirama2

1. **Colonnes de Catégorisation** :
   - `cat_auto`, `cat_confidence` (batch)
   - `cat_user`, `cat_date_user`, `cat_validee` (client)

2. **Stratégie Multi-Version** :
   - Batch écrit avec timestamp constant
   - Client écrit avec timestamp réel
   - Pas d'écrasement en cas de rejeu batch

3. **Données Thrift Binaires** :
   - Stockage en BLOB
   - Colonnes dynamiques pour filtrage

### Points d'Attention

- **Intégration avec Domirama2** : Décision à prendre (extension de table ou table séparée)
- **Migration Thrift** : Préservation de l'intégrité des données binaires
- **Performance** : Validation des performances avec index SAI

---

## 🎯 Prochaines Étapes

1. ✅ Analyse complète (FAIT)
2. ⏳ Création des schémas CQL
3. ⏳ Création des scripts de démonstration
4. ⏳ Exécution et validation
5. ⏳ Documentation des résultats

---

**Date de création** : 2024-11-27  
**Version** : 1.0

