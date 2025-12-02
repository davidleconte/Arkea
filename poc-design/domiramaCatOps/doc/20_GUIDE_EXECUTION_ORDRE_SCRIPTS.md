# 📋 Guide d'Exécution : Ordre des Scripts et Tests Unitaires

**Date** : 2025-01-XX  
**Dernière mise à jour** : 2025-01-XX  
**Version** : 1.0  
**Objectif** : Définir l'ordre d'exécution des scripts et les tests unitaires pour chaque script  
**Format** : Guide séquentiel avec dépendances

> **Note** : Pour un index complet des use cases et scripts, voir [18_INDEX_USE_CASES_SCRIPTS.md](18_INDEX_USE_CASES_SCRIPTS.md).

---

## 📊 Vue d'Ensemble

**Total Scripts** : **29 scripts**  
**Phases** : **6 phases** (Setup, Génération, Chargement, Tests, Recherche, Démonstrations)

---

## 🔗 Liens vers les Scripts

Tous les scripts sont situés dans le répertoire `scripts/` :

- **Phase 1 (Setup)** : [`01_setup_domiramaCatOps_keyspace.sh`](../scripts/01_setup_domiramaCatOps_keyspace.sh), [`02_setup_operations_by_account.sh`](../scripts/02_setup_operations_by_account.sh), [`03_setup_meta_categories_tables.sh`](../scripts/03_setup_meta_categories_tables.sh), [`04_create_indexes.sh`](../scripts/04_create_indexes.sh)
- **Phase 2 (Génération)** : [`04_generate_operations_parquet.sh`](../scripts/04_generate_operations_parquet.sh), [`04_generate_meta_categories_parquet.sh`](../scripts/04_generate_meta_categories_parquet.sh), [`05_generate_libelle_embedding.sh`](../scripts/05_generate_libelle_embedding.sh)
- **Phase 3 (Chargement)** : [`05_load_operations_data_parquet.sh`](../scripts/05_load_operations_data_parquet.sh), [`06_load_meta_categories_data_parquet.sh`](../scripts/06_load_meta_categories_data_parquet.sh), [`07_load_category_data_realtime.sh`](../scripts/07_load_category_data_realtime.sh)
- **Phase 4 (Tests)** : [`08_test_category_search.sh`](../scripts/08_test_category_search.sh), [`09_test_acceptation_opposition.sh`](../scripts/09_test_acceptation_opposition.sh), [`10_test_regles_personnalisees.sh`](../scripts/10_test_regles_personnalisees.sh), [`11_test_feedbacks_counters.sh`](../scripts/11_test_feedbacks_counters.sh), [`12_test_historique_opposition.sh`](../scripts/12_test_historique_opposition.sh), [`13_test_dynamic_columns.sh`](../scripts/13_test_dynamic_columns.sh), [`14_test_incremental_export.sh`](../scripts/14_test_incremental_export.sh), [`15_test_coherence_multi_tables.sh`](../scripts/15_test_coherence_multi_tables.sh)
- **Phase 5 (Recherche)** : [`16_test_fuzzy_search.sh`](../scripts/16_test_fuzzy_search.sh), [`17_demonstration_fuzzy_search.sh`](../scripts/17_demonstration_fuzzy_search.sh), [`18_test_hybrid_search.sh`](../scripts/18_test_hybrid_search.sh)
- **Phase 6 (Démonstrations)** : [`19_demo_ttl.sh`](../scripts/19_demo_ttl.sh), [`21_demo_bloomfilter_equivalent.sh`](../scripts/21_demo_bloomfilter_equivalent.sh), [`22_demo_replication_scope.sh`](../scripts/22_demo_replication_scope.sh), [`24_demo_data_api.sh`](../scripts/24_demo_data_api.sh), [`27_demo_kafka_streaming.sh`](../scripts/27_demo_kafka_streaming.sh)

Voir aussi : [18_INDEX_USE_CASES_SCRIPTS.md](18_INDEX_USE_CASES_SCRIPTS.md) pour le mapping complet use cases ↔ scripts.

---

## 🔧 PHASE 1 : SETUP ET CONFIGURATION (Scripts 01-04)

### Ordre d'Exécution

| # | Script | Dépendances | Durée Estimée | Tests Unitaires |
|---|--------|-------------|---------------|-----------------|
| 01 | `01_setup_domiramaCatOps_keyspace.sh` | HCD démarré | 2 min | ✅ Vérifier keyspace créé |
| 02 | `02_setup_operations_by_account.sh` | Script 01 | 3 min | ✅ Vérifier table créée |
| 03 | `03_setup_meta_categories_tables.sh` | Script 01 | 5 min | ✅ Vérifier 7 tables créées |
| 04 | `04_create_indexes.sh` | Scripts 01, 02, 03 | 5 min | ✅ Vérifier index créés |

### Commandes d'Exécution

```bash
cd /Users/david.leconte/Documents/Arkea/poc-design/domiramaCatOps/scripts

# 1. Créer le keyspace
./01_setup_domiramaCatOps_keyspace.sh

# 2. Créer la table operations_by_account
./02_setup_operations_by_account.sh

# 3. Créer les 7 tables meta-categories
./03_setup_meta_categories_tables.sh

# 4. Créer tous les index SAI
./04_create_indexes.sh
```

### Tests Unitaires Phase 1

#### Test 01 : Vérification Keyspace

```bash
# Vérifier que le keyspace existe
${HCD_DIR}/bin/cqlsh -e "DESCRIBE KEYSPACE domiramacatops_poc;"
# ✅ Attendu : Keyspace avec replication SimpleStrategy
```

#### Test 02 : Vérification Table Operations

```bash
# Vérifier que la table existe avec toutes les colonnes
${HCD_DIR}/bin/cqlsh -e "DESCRIBE TABLE domiramacatops_poc.operations_by_account;"
# ✅ Attendu : Table avec colonnes cat_auto, cat_user, cat_confidence, etc.
```

#### Test 03 : Vérification Tables Meta-Categories

```bash
# Vérifier les 7 tables
${HCD_DIR}/bin/cqlsh -e "USE domiramacatops_poc; DESCRIBE TABLES;"
# ✅ Attendu : 8 tables (operations_by_account + 7 meta-categories)
```

#### Test 04 : Vérification Index SAI

```bash
# Vérifier les index créés
${HCD_DIR}/bin/cqlsh -e "SELECT index_name, table_name FROM system_schema.indexes WHERE keyspace_name = 'domiramacatops_poc';"
# ✅ Attendu : Index sur cat_auto, cat_user, libelle, libelle_tokens, libelle_embedding, etc.
```

---

## 📦 PHASE 2 : GÉNÉRATION DE DONNÉES (Scripts 04-05)

### Ordre d'Exécution

| # | Script | Dépendances | Durée Estimée | Tests Unitaires |
|---|--------|-------------|---------------|-----------------|
| 04a | `04_generate_operations_parquet.sh` | Aucune | 10 min | ✅ Vérifier fichier Parquet (20k+ lignes) |
| 04b | `04_generate_meta_categories_parquet.sh` | Aucune | 5 min | ✅ Vérifier 7 fichiers Parquet |
| 05c | `05_generate_libelle_embedding.sh` | Script 04a | 30 min | ✅ Vérifier embeddings générés |

**Note** : Les scripts 04a et 04b peuvent être exécutés en parallèle.

### Commandes d'Exécution

```bash
# 1. Générer les opérations (20k+ lignes)
./04_generate_operations_parquet.sh

# 2. Générer les meta-categories (peut être fait en parallèle)
./04_generate_meta_categories_parquet.sh

# 3. Générer les embeddings ByteT5 (nécessite opérations générées)
./05_generate_libelle_embedding.sh
```

### Tests Unitaires Phase 2

#### Test 05 : Vérification Fichier Operations Parquet

```bash
# Vérifier le fichier Parquet
python3 << EOF
import pandas as pd
df = pd.read_parquet('data/operations_20000.parquet')
print(f"✅ Nombre de lignes : {len(df)}")
print(f"✅ Colonnes : {list(df.columns)}")
assert len(df) >= 20000, "❌ Moins de 20 000 lignes"
EOF
# ✅ Attendu : >= 20 000 lignes, colonnes code_si, contrat, date_op, etc.
```

#### Test 06 : Vérification Fichiers Meta-Categories Parquet

```bash
# Vérifier les 7 fichiers Parquet
for table in acceptations oppositions feedbacks_libelles feedbacks_ics regles_personnalisees decisions_salaires historique_oppositions; do
    if [ -f "data/${table}.parquet" ]; then
        echo "✅ ${table}.parquet existe"
    else
        echo "❌ ${table}.parquet manquant"
    fi
done
# ✅ Attendu : 7 fichiers Parquet présents
```

#### Test 07 : Vérification Embeddings

```bash
# Vérifier que les embeddings sont générés
python3 << EOF
import pandas as pd
df = pd.read_parquet('data/operations_20000.parquet')
if 'libelle_embedding' in df.columns:
    print(f"✅ Colonne libelle_embedding présente")
    print(f"✅ Embeddings non-nuls : {df['libelle_embedding'].notna().sum()}")
else:
    print("❌ Colonne libelle_embedding manquante")
EOF
# ✅ Attendu : Colonne libelle_embedding avec embeddings non-nuls
```

---

## 📥 PHASE 3 : CHARGEMENT DES DONNÉES (Scripts 05-07)

### Ordre d'Exécution

| # | Script | Dépendances | Durée Estimée | Tests Unitaires |
|---|--------|-------------|---------------|-----------------|
| 05 | `05_load_operations_data_parquet.sh` | Scripts 01-04, 04a, 05c | 15 min | ✅ Vérifier données chargées |
| 05b | `05_update_feedbacks_counters.sh` | Script 05 | 2 min | ✅ Vérifier compteurs mis à jour |
| 06 | `06_load_meta_categories_data_parquet.sh` | Scripts 01-04, 04b | 10 min | ✅ Vérifier 7 tables chargées |
| 07 | `07_load_category_data_realtime.sh` | Script 05 | 5 min | ✅ Vérifier corrections client |

### Commandes d'Exécution

```bash
# 1. Charger les opérations (batch)
./05_load_operations_data_parquet.sh data/operations_20000.parquet

# 2. Mettre à jour les feedbacks (optionnel)
./05_update_feedbacks_counters.sh

# 3. Charger les meta-categories
./06_load_meta_categories_data_parquet.sh

# 4. Charger les corrections client (temps réel)
./07_load_category_data_realtime.sh
```

### Tests Unitaires Phase 3

#### Test 08 : Vérification Chargement Operations

```bash
# Vérifier le nombre d'opérations chargées
${HCD_DIR}/bin/cqlsh -e "SELECT COUNT(*) FROM domiramacatops_poc.operations_by_account;"
# ✅ Attendu : >= 20 000 lignes
```

#### Test 09 : Vérification Catégorisation Automatique

```bash
# Vérifier que cat_auto est rempli
${HCD_DIR}/bin/cqlsh -e "SELECT COUNT(*) FROM domiramacatops_poc.operations_by_account WHERE cat_auto IS NOT NULL;"
# ✅ Attendu : >= 20 000 (toutes les opérations catégorisées)
```

#### Test 10 : Vérification Chargement Meta-Categories

```bash
# Vérifier chaque table meta-categories
for table in acceptations oppositions feedbacks_libelles feedbacks_ics regles_personnalisees decisions_salaires historique_oppositions; do
    count=$(${HCD_DIR}/bin/cqlsh -e "SELECT COUNT(*) FROM domiramacatops_poc.${table};" | grep -o '[0-9]*' | head -1)
    echo "✅ ${table}: ${count} lignes"
done
# ✅ Attendu : Chaque table contient des données
```

#### Test 11 : Vérification Corrections Client

```bash
# Vérifier que cat_user est rempli pour certaines opérations
${HCD_DIR}/bin/cqlsh -e "SELECT COUNT(*) FROM domiramacatops_poc.operations_by_account WHERE cat_user IS NOT NULL;"
# ✅ Attendu : > 0 (au moins quelques corrections client)
```

---

## 🧪 PHASE 4 : TESTS FONCTIONNELS (Scripts 08-15)

### Ordre d'Exécution

| # | Script | Dépendances | Durée Estimée | Tests Unitaires |
|---|--------|-------------|---------------|-----------------|
| 08 | `08_test_category_search.sh` | Script 05 | 3 min | ✅ Vérifier recherche par catégorie |
| 09 | `09_test_acceptation_opposition.sh` | Script 06 | 3 min | ✅ Vérifier acceptation/opposition |
| 10 | `10_test_regles_personnalisees.sh` | Scripts 05, 06 | 3 min | ✅ Vérifier règles personnalisées |
| 11 | `11_test_feedbacks_counters.sh` | Script 05 | 3 min | ✅ Vérifier compteurs feedbacks |
| 12 | `12_test_historique_opposition.sh` | Script 06 | 3 min | ✅ Vérifier historique |
| 13 | `13_test_dynamic_columns.sh` | Script 05 | 3 min | ✅ Vérifier colonnes dynamiques |
| 14 | `14_test_incremental_export.sh` | Script 05 | 5 min | ✅ Vérifier export Parquet |
| 15 | `15_test_coherence_multi_tables.sh` | Scripts 05, 06 | 5 min | ✅ Vérifier cohérence |

**Note** : Les scripts 08-15 peuvent être exécutés en parallèle (sauf dépendances).

### Commandes d'Exécution

```bash
# Tests fonctionnels (peuvent être exécutés en parallèle)
./08_test_category_search.sh &
./09_test_acceptation_opposition.sh &
./10_test_regles_personnalisees.sh &
./11_test_feedbacks_counters.sh &
./12_test_historique_opposition.sh &
./13_test_dynamic_columns.sh &
./14_test_incremental_export.sh &
./15_test_coherence_multi_tables.sh &

# Attendre la fin de tous les tests
wait
```

### Tests Unitaires Phase 4

#### Test 12 : Vérification Recherche par Catégorie

```bash
# Vérifier que la recherche par catégorie fonctionne
${HCD_DIR}/bin/cqlsh -e "SELECT COUNT(*) FROM domiramacatops_poc.operations_by_account WHERE cat_auto = 'ALIMENTATION' ALLOW FILTERING;"
# ✅ Attendu : > 0 (résultats trouvés)
```

#### Test 13 : Vérification Acceptation/Opposition

```bash
# Vérifier que les acceptations/oppositions sont enregistrées
${HCD_DIR}/bin/cqlsh -e "SELECT COUNT(*) FROM domiramacatops_poc.acceptations;"
${HCD_DIR}/bin/cqlsh -e "SELECT COUNT(*) FROM domiramacatops_poc.oppositions;"
# ✅ Attendu : > 0 pour chaque table
```

#### Test 14 : Vérification Règles Personnalisées

```bash
# Vérifier que les règles sont appliquées
${HCD_DIR}/bin/cqlsh -e "SELECT COUNT(*) FROM domiramacatops_poc.regles_personnalisees;"
# ✅ Attendu : > 0 (règles créées)
```

#### Test 15 : Vérification Compteurs Feedbacks

```bash
# Vérifier que les compteurs sont incrémentés
${HCD_DIR}/bin/cqlsh -e "SELECT libelle, count FROM domiramacatops_poc.feedbacks_libelles LIMIT 5;"
# ✅ Attendu : Compteurs > 0
```

#### Test 16 : Vérification Export Incrémental

```bash
# Vérifier que le fichier Parquet exporté existe
if [ -f "data/exports/operations_2024-01.parquet" ]; then
    echo "✅ Export Parquet créé"
    python3 -c "import pandas as pd; df = pd.read_parquet('data/exports/operations_2024-01.parquet'); print(f'✅ {len(df)} lignes exportées')"
else
    echo "❌ Export Parquet manquant"
fi
# ✅ Attendu : Fichier Parquet avec données
```

---

## 🔍 PHASE 5 : RECHERCHE AVANCÉE (Scripts 16-18)

### Ordre d'Exécution

| # | Script | Dépendances | Durée Estimée | Tests Unitaires |
|---|--------|-------------|---------------|-----------------|
| 16 | `16_test_fuzzy_search.sh` | Scripts 05, 05c | 5 min | ✅ Vérifier fuzzy search |
| 17 | `17_demonstration_fuzzy_search.sh` | Scripts 05, 05c | 10 min | ✅ Vérifier démonstration complète |
| 18 | `18_test_hybrid_search.sh` | Scripts 05, 05c | 5 min | ✅ Vérifier hybrid search |

### Commandes d'Exécution

```bash
# 1. Tests fuzzy search
./16_test_fuzzy_search.sh

# 2. Démonstration complète fuzzy search
./17_demonstration_fuzzy_search.sh

# 3. Tests hybrid search
./18_test_hybrid_search.sh
```

### Tests Unitaires Phase 5

#### Test 17 : Vérification Fuzzy Search

```python
# Vérifier que la recherche vectorielle fonctionne
python3 << EOF
from cassandra.cluster import Cluster
cluster = Cluster(['localhost'])
session = cluster.connect('domiramacatops_poc')

# Test recherche vectorielle
result = session.execute("""
    SELECT libelle, cat_auto
    FROM operations_by_account
    WHERE code_si = '01' AND contrat = '5913101072'
    ORDER BY libelle_embedding ANN OF [0.1, 0.2, ...] LIMIT 5;
""")
print(f"✅ Fuzzy search fonctionne : {len(list(result))} résultats")
EOF
# ✅ Attendu : Résultats retournés
```

#### Test 18 : Vérification Hybrid Search

```python
# Vérifier que la recherche hybride fonctionne
python3 << EOF
from cassandra.cluster import Cluster
cluster = Cluster(['localhost'])
session = cluster.connect('domiramacatops_poc')

# Test recherche hybride (full-text + vector)
result = session.execute("""
    SELECT libelle, cat_auto
    FROM operations_by_account
    WHERE code_si = '01' AND contrat = '5913101072'
      AND libelle : 'CARREFOUR'
    ORDER BY libelle_embedding ANN OF [0.1, 0.2, ...] LIMIT 5;
""")
print(f"✅ Hybrid search fonctionne : {len(list(result))} résultats")
EOF
# ✅ Attendu : Résultats retournés
```

---

## 🎯 PHASE 6 : DÉMONSTRATIONS (Scripts 19-27)

### Ordre d'Exécution

| # | Script | Dépendances | Durée Estimée | Tests Unitaires |
|---|--------|-------------|---------------|-----------------|
| 19 | `19_demo_ttl.sh` | Script 05 | 5 min | ✅ Vérifier TTL et purge |
| 21 | `21_demo_bloomfilter_equivalent.sh` | Script 05 | 5 min | ✅ Vérifier performance index |
| 22 | `22_demo_replication_scope.sh` | Script 01 | 3 min | ✅ Vérifier configuration réplication |
| 24 | `24_demo_data_api.sh` | Scripts 05, 06 | 5 min | ✅ Vérifier Data API (si configurée) |
| 25 | `25_test_feedbacks_ics.sh` | Script 05 | 3 min | ✅ Vérifier feedbacks ICS |
| 26 | `26_test_decisions_salaires.sh` | Script 06 | 3 min | ✅ Vérifier décisions salaires |
| 27 | `27_demo_kafka_streaming.sh` | Scripts 05, Kafka | 10 min | ✅ Vérifier streaming (si Kafka démarré) |

**Note** : Les scripts 19, 21, 22, 24, 25, 26 peuvent être exécutés en parallèle.

### Commandes d'Exécution

```bash
# Démonstrations (peuvent être exécutées en parallèle)
./19_demo_ttl.sh &
./21_demo_bloomfilter_equivalent.sh &
./22_demo_replication_scope.sh &
./24_demo_data_api.sh &
./25_test_feedbacks_ics.sh &
./26_test_decisions_salaires.sh &

# Attendre la fin
wait

# Kafka Streaming (nécessite Kafka démarré)
./27_demo_kafka_streaming.sh
```

### Tests Unitaires Phase 6

#### Test 19 : Vérification TTL

```bash
# Vérifier que le TTL est configuré
${HCD_DIR}/bin/cqlsh -e "SELECT default_time_to_live FROM system_schema.tables WHERE keyspace_name = 'domiramacatops_poc' AND table_name = 'operations_by_account';"
# ✅ Attendu : default_time_to_live = 315360000 (10 ans)
```

#### Test 20 : Vérification Performance Index

```bash
# Vérifier que les index SAI améliorent les performances
time ${HCD_DIR}/bin/cqlsh -e "SELECT * FROM domiramacatops_poc.operations_by_account WHERE cat_auto = 'ALIMENTATION' ALLOW FILTERING LIMIT 10;"
# ✅ Attendu : Temps d'exécution < 100ms
```

#### Test 21 : Vérification Feedbacks ICS

```bash
# Vérifier que les compteurs ICS sont incrémentés
${HCD_DIR}/bin/cqlsh -e "SELECT code_categorie, count FROM domiramacatops_poc.feedbacks_ics LIMIT 5;"
# ✅ Attendu : Compteurs > 0
```

---

## 📋 ORDRE D'EXÉCUTION COMPLET (Séquentiel)

### Script d'Orchestration Complet

```bash
#!/bin/bash
# ============================================
# Script d'Orchestration : Exécution Complète POC DomiramaCatOps
# ============================================

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

echo "🚀 Démarrage de l'exécution complète du POC DomiramaCatOps"
echo ""

# ============================================
# PHASE 1 : SETUP
# ============================================
echo "📋 PHASE 1 : Setup et Configuration"
./01_setup_domiramaCatOps_keyspace.sh
./02_setup_operations_by_account.sh
./03_setup_meta_categories_tables.sh
./04_create_indexes.sh
echo "✅ Phase 1 terminée"
echo ""

# ============================================
# PHASE 2 : GÉNÉRATION
# ============================================
echo "📦 PHASE 2 : Génération de Données"
./04_generate_operations_parquet.sh &
./04_generate_meta_categories_parquet.sh &
wait
./05_generate_libelle_embedding.sh
echo "✅ Phase 2 terminée"
echo ""

# ============================================
# PHASE 3 : CHARGEMENT
# ============================================
echo "📥 PHASE 3 : Chargement des Données"
./05_load_operations_data_parquet.sh data/operations_20000.parquet
./05_update_feedbacks_counters.sh
./06_load_meta_categories_data_parquet.sh
./07_load_category_data_realtime.sh
echo "✅ Phase 3 terminée"
echo ""

# ============================================
# PHASE 4 : TESTS FONCTIONNELS
# ============================================
echo "🧪 PHASE 4 : Tests Fonctionnels"
./08_test_category_search.sh &
./09_test_acceptation_opposition.sh &
./10_test_regles_personnalisees.sh &
./11_test_feedbacks_counters.sh &
./12_test_historique_opposition.sh &
./13_test_dynamic_columns.sh &
./14_test_incremental_export.sh &
./15_test_coherence_multi_tables.sh &
wait
echo "✅ Phase 4 terminée"
echo ""

# ============================================
# PHASE 5 : RECHERCHE AVANCÉE
# ============================================
echo "🔍 PHASE 5 : Recherche Avancée"
./16_test_fuzzy_search.sh
./17_demonstration_fuzzy_search.sh
./18_test_hybrid_search.sh
echo "✅ Phase 5 terminée"
echo ""

# ============================================
# PHASE 6 : DÉMONSTRATIONS
# ============================================
echo "🎯 PHASE 6 : Démonstrations"
./19_demo_ttl.sh &
./21_demo_bloomfilter_equivalent.sh &
./22_demo_replication_scope.sh &
./24_demo_data_api.sh &
./25_test_feedbacks_ics.sh &
./26_test_decisions_salaires.sh &
wait
./27_demo_kafka_streaming.sh
echo "✅ Phase 6 terminée"
echo ""

echo "🎉 Exécution complète terminée avec succès !"
```

---

## ✅ CHECKLIST DE VALIDATION

### Avant de Commencer

- [ ] HCD démarré (`./scripts/setup/03_start_hcd.sh` depuis la racine)
- [ ] Java 11 configuré (`jenv local 11`)
- [ ] Spark 3.5.1 installé et configuré
- [ ] Variables d'environnement configurées (`.poc-profile`)
- [ ] Python 3.8+ avec dépendances installées

### Après Phase 1 (Setup)

- [ ] Keyspace `domiramacatops_poc` créé
- [ ] Table `operations_by_account` créée
- [ ] 7 tables meta-categories créées
- [ ] Index SAI créés

### Après Phase 2 (Génération)

- [ ] Fichier `data/operations_20000.parquet` avec >= 20 000 lignes
- [ ] 7 fichiers Parquet meta-categories générés
- [ ] Embeddings ByteT5 générés

### Après Phase 3 (Chargement)

- [ ] >= 20 000 opérations chargées dans HCD
- [ ] Meta-categories chargées dans les 7 tables
- [ ] Corrections client chargées

### Après Phase 4 (Tests)

- [ ] Tous les tests fonctionnels passent
- [ ] Rapports de démonstration générés dans `doc/demonstrations/`

### Après Phase 5 (Recherche)

- [ ] Fuzzy search fonctionne
- [ ] Hybrid search fonctionne
- [ ] Scripts Python de recherche exécutés avec succès

### Après Phase 6 (Démonstrations)

- [ ] TTL et purge démontrés
- [ ] BLOOMFILTER équivalent démontré
- [ ] REPLICATION_SCOPE démontré
- [ ] Data API démontrée (si configurée)
- [ ] Kafka Streaming démontré (si Kafka démarré)

---

## 🐛 DÉPANNAGE

### Problème : Script échoue avec erreur de connexion HCD

**Solution** :

```bash
# Vérifier que HCD est démarré
ps aux | grep cassandra

# Redémarrer HCD si nécessaire
cd /Users/david.leconte/Documents/Arkea
./scripts/setup/03_start_hcd.sh
```

### Problème : Script échoue avec erreur Java

**Solution** :

```bash
# Vérifier la version Java
jenv local 11
java -version
# ✅ Attendu : Java 11
```

### Problème : Script échoue avec erreur Spark

**Solution** :

```bash
# Vérifier que Spark est installé
which spark-submit

# Vérifier les variables d'environnement
source .poc-profile
echo $SPARK_HOME
```

### Problème : Données non chargées

**Solution** :

```bash
# Vérifier que les fichiers Parquet existent
ls -lh data/*.parquet

# Réexécuter la génération si nécessaire
./04_generate_operations_parquet.sh
```

---

## 📊 TEMPS TOTAL ESTIMÉ

| Phase | Durée Estimée |
|-------|---------------|
| Phase 1 : Setup | 15 min |
| Phase 2 : Génération | 45 min (30 min pour embeddings) |
| Phase 3 : Chargement | 32 min |
| Phase 4 : Tests | 28 min (parallélisé) |
| Phase 5 : Recherche | 20 min |
| Phase 6 : Démonstrations | 34 min (parallélisé) |
| **TOTAL** | **~2h30** (séquentiel) ou **~1h30** (parallélisé) |

---

## ✅ CONCLUSION

**Ordre d'exécution recommandé** :

1. ✅ Phase 1 : Setup (séquentiel)
2. ✅ Phase 2 : Génération (parallélisé sauf embeddings)
3. ✅ Phase 3 : Chargement (séquentiel)
4. ✅ Phase 4 : Tests (parallélisé)
5. ✅ Phase 5 : Recherche (séquentiel)
6. ✅ Phase 6 : Démonstrations (parallélisé sauf Kafka)

**Tests unitaires** : Exécuter après chaque phase pour valider avant de passer à la suivante.

---

**Date** : 2025-01-XX  
**Version** : 1.0
