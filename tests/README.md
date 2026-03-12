# 🧪 Tests - ARKEA

**Date** : 2026-03-12
**Objectif** : Structure et guide pour les tests du projet ARKEA
**Version** : 1.4.1

---

## 📁 Structure

```
tests/
├── unit/              # Tests unitaires (fonctions individuelles)
│   ├── test_portability.sh
│   ├── test_consistency.sh
│   ├── test_poc_config.sh
│   └── test_portable_functions_example.sh
├── integration/       # Tests d'intégration (composants ensemble)
│   ├── test_poc_structure.sh
│   └── test_hcd_spark.sh
├── e2e/              # Tests end-to-end (scénarios complets)
│   └── test_kafka_hcd_pipeline.sh
├── fixtures/          # Données de test réutilisables
├── utils/             # Framework de tests
│   └── test_framework.sh
├── run_all_tests.sh   # Exécuter tous les tests
├── run_unit_tests.sh  # Exécuter tests unitaires
├── run_integration_tests.sh  # Exécuter tests d'intégration
├── run_e2e_tests.sh   # Exécuter tests E2E
├── run_portability_tests.sh  # Exécuter tests de portabilité
├── run_consistency_tests.sh  # Exécuter tests de cohérence
└── README.md          # Ce fichier
```

---

## 🎯 Types de Tests

### Tests Unitaires (`unit/`)

**Objectif** : Tester des fonctions individuelles en isolation

**Tests disponibles** :

- `test_portability.sh` : Tests de portabilité cross-platform (5 tests)
- `test_consistency.sh` : Tests de cohérence du projet (6 tests)
- `test_poc_config.sh` : Tests de configuration POC (7 tests)
- `test_portable_functions_example.sh` : Exemple de tests pour fonctions portables (5 tests)

**Exemple** :

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Charger le framework de tests
source "$ARKEA_HOME/tests/utils/test_framework.sh"

# Charger les fonctions à tester
source "$ARKEA_HOME/scripts/utils/portable_functions.sh"

test_suite_start "Tests des fonctions portables"

assert_equal "$(get_realpath /tmp)" "/tmp" "get_realpath fonctionne"
assert_command_exists "java" "Java est installé"

test_suite_end
```

### Tests d'Intégration (`integration/`)

**Objectif** : Tester l'interaction entre composants

**Tests disponibles** :

- `test_poc_structure.sh` : Tests de structure des POCs
- `test_hcd_spark.sh` : Tests d'intégration HCD ↔ Spark (4 tests)

**Exemple** :

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$ARKEA_HOME/tests/utils/test_framework.sh"
source "$ARKEA_HOME/.poc-config.sh"

test_suite_start "Tests d'intégration HCD ↔ Spark"

assert_port_open "${HCD_PORT:-9042}" "HCD devrait être démarré"
assert_dir_exists "$SPARK_HOME" "SPARK_HOME devrait exister"

test_suite_end
```

### Tests End-to-End (`e2e/`)

**Objectif** : Tester des scénarios complets

**Tests disponibles** :

- `test_kafka_hcd_pipeline.sh` : Test end-to-end pipeline Kafka → HCD (6 tests)

**Exemple** :

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$ARKEA_HOME/tests/utils/test_framework.sh"
source "$ARKEA_HOME/.poc-config.sh"

test_suite_start "Test E2E Pipeline Kafka → HCD"

assert_port_open "${HCD_PORT:-9042}" "HCD devrait être démarré"
assert_port_open "9092" "Kafka devrait être démarré"

# Tests de création keyspace, table, topic, etc.

test_suite_end
```

---

## 🚀 Exécution

### Tous les Tests

```bash
./tests/run_all_tests.sh
```

### Tests par Catégorie

```bash
# Tests unitaires uniquement
./tests/run_unit_tests.sh

# Tests d'intégration uniquement
./tests/run_integration_tests.sh

# Tests E2E uniquement
./tests/run_e2e_tests.sh

# Tests de portabilité uniquement
./tests/run_portability_tests.sh

# Tests de cohérence uniquement
./tests/run_consistency_tests.sh
```

---

## 📋 Standards

### Framework de Tests

Le projet utilise un framework de tests réutilisable (`tests/utils/test_framework.sh`) :

**Fonctions disponibles** :

- `test_suite_start(name)` : Début d'une suite de tests
- `test_suite_end()` : Fin avec résumé automatique
- `assert_equal(expected, actual, message)` : Assertion d'égalité
- `assert_not_equal(expected, actual, message)` : Assertion de différence
- `assert_file_exists(file, message)` : Vérification fichier
- `assert_dir_exists(dir, message)` : Vérification répertoire
- `assert_port_open(port, message)` : Vérification port
- `assert_command_exists(cmd, message)` : Vérification commande
- `assert_var_defined(var_name, message)` : Vérification variable
- `assert_file_contains(file, pattern, message)` : Vérification contenu

### Structure d'un Test

```bash
#!/bin/bash
set -euo pipefail

# =============================================================================
# Test : Nom du Test
# =============================================================================
# Date : 2025-12-02
# Description : Description du test
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Charger le framework de tests
source "$ARKEA_HOME/tests/utils/test_framework.sh"

# Charger les fonctions à tester (si nécessaire)
source "$ARKEA_HOME/scripts/utils/portable_functions.sh"

# Début de la suite de tests
test_suite_start "Tests des fonctions portables"

# Tests avec assertions
assert_equal "$(get_realpath /tmp)" "/tmp" "get_realpath fonctionne"
assert_command_exists "java" "Java est installé"
assert_file_exists "$ARKEA_HOME/.poc-config.sh" ".poc-config.sh devrait exister"

# Fin de la suite de tests (résumé automatique)
test_suite_end

# Code de sortie basé sur les résultats
if [ $TEST_FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
```

---

## 📊 Couverture

**Objectif** : 80%+ de couverture de code

**État actuel** :

- ✅ **Tests unitaires** : 4 fichiers (23+ tests)
  - Tests de portabilité (5 tests)
  - Tests de cohérence (6 tests)
  - Tests de configuration (7 tests)
  - Tests de fonctions portables (5 tests)
- ✅ **Tests d'intégration** : 2 fichiers (4+ tests)
  - Tests de structure POC
  - Tests HCD ↔ Spark (4 tests)
- ✅ **Tests E2E** : 1 fichier (6 tests)
  - Test pipeline Kafka → HCD complet

**Mesure** :

- Tests unitaires : Fonctions individuelles
- Tests d'intégration : Interactions entre composants
- Tests E2E : Scénarios complets

---

## 🔧 Fixtures

Les fixtures sont dans `tests/fixtures/` :

- Données de test réutilisables
- Configurations de test
- Schémas de test

---

## 📝 Ajouter un Test

1. Créer le fichier dans le répertoire approprié
2. Suivre la structure standard
3. Ajouter au script d'exécution correspondant
4. Documenter dans ce README

---

**Pour plus d'informations, voir** :

- `CONTRIBUTING.md` - Guide de contribution
- `docs/TROUBLESHOOTING.md` - Guide de dépannage
