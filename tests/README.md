# 🧪 Tests - ARKEA

**Date** : 2025-12-01  
**Objectif** : Structure et guide pour les tests du projet ARKEA

---

## 📁 Structure

```
tests/
├── unit/              # Tests unitaires (fonctions individuelles)
├── integration/       # Tests d'intégration (composants ensemble)
├── e2e/              # Tests end-to-end (scénarios complets)
├── fixtures/          # Données de test réutilisables
└── README.md          # Ce fichier
```

---

## 🎯 Types de Tests

### Tests Unitaires (`unit/`)

**Objectif** : Tester des fonctions individuelles en isolation

**Tests disponibles** :
- `test_portability.sh` : Tests de portabilité cross-platform
- `test_consistency.sh` : Tests de cohérence du projet

**Exemple** :
```bash
# tests/unit/test_setup_paths.sh
#!/bin/bash
source ../../utils/didactique_functions.sh
# Tests de setup_paths()
```

### Tests d'Intégration (`integration/`)

**Objectif** : Tester l'interaction entre composants

**Tests disponibles** :
- `test_poc_structure.sh` : Tests de structure des POCs

**Exemple** :
```bash
# tests/integration/test_hcd_spark.sh
#!/bin/bash
# Test de l'intégration HCD ↔ Spark
```

### Tests End-to-End (`e2e/`)

**Objectif** : Tester des scénarios complets

**Exemple** :
```bash
# tests/e2e/test_kafka_hcd_pipeline.sh
#!/bin/bash
# Test complet du pipeline Kafka → HCD
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

### Structure d'un Test

```bash
#!/bin/bash
set -euo pipefail

# =============================================================================
# Test : Nom du Test
# =============================================================================
# Date : 2025-12-01
# Description : Description du test
# =============================================================================

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../utils/didactique_functions.sh"
setup_paths

# Variables de test
TEST_NAME="test_exemple"
PASSED=0
FAILED=0

# Fonction de test
test_function() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    
    if [ "$expected" = "$actual" ]; then
        echo "✅ $test_name"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo "❌ $test_name (expected: $expected, got: $actual)"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# Tests
test_function "test_1" "expected_value" "actual_value"

# Résumé
echo ""
echo "Tests passés: $PASSED"
echo "Tests échoués: $FAILED"
exit $FAILED
```

---

## 📊 Couverture

**Objectif** : 80%+ de couverture de code

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

