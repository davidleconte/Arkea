# 🎯 Plan d'Action Détaillé - Priorités 1 et 3

**Date** : 2025-12-02  
**Objectif** : Plans d'action détaillés pour améliorer les scores des priorités
1 (Tests) et 3 (CI/CD)  
**Référence** : `AUDIT_MCKINSEY_MECE_COMPLET_ARKEA_2025.md`

---

## 📋 Table des Matières

1. [PRIORITÉ 1 : Tests Unitaires et d'Intégration](#priorité-1--tests-unitaires-et-dintégration)
2. [PRIORITÉ 3 : Enrichir CI/CD](#priorité-3--enrichir-cicd)
3. [Métriques de Succès](#métriques-de-succès)
4. [Timeline et Ressources](#timeline-et-ressources)

---

## 🧪 PRIORITÉ 1 : Tests Unitaires et d'Intégration

**Score actuel** : **82/100**  
**Score cible** : **90/100**  
**Impact** : **+8 points**  
**Effort estimé** : **5-7 jours**

### 1.1 État Actuel

#### Points Forts ✅

- ✅ Structure de tests créée (`tests/unit/`, `tests/integration/`, `tests/e2e/`)
- ✅ Scripts d'exécution présents (`run_all_tests.sh`, `run_unit_tests.sh`, etc.)
- ✅ Documentation complète (`tests/README.md`)
- ✅ 197 scripts de démonstration fonctionnels excellents

#### Gaps Identifiés ⚠️

- ⚠️ **Tests unitaires** : 2 fichiers seulement (`test_portability.sh`, `test_consistency.sh`)
- ⚠️ **Tests d'intégration** : 1 fichier (`test_poc_structure.sh`)
- ❌ **Tests E2E** : Répertoire vide
- ⚠️ **Fixtures** : Répertoire créé mais vide
- ⚠️ **Couverture** : Pas de mesure de couverture

---

### 1.2 Plan d'Action Détaillé

#### Phase 1 : Framework de Tests (Jour 1)

**Objectif** : Créer un framework de tests réutilisable

##### 1.2.1 Créer `tests/utils/test_framework.sh`

**Fonctions à implémenter** :

- `test_suite_start(name)` : Début d'une suite de tests
- `test_suite_end()` : Fin d'une suite avec résumé
- `assert_equal(expected, actual, message)` : Assertion d'égalité
- `assert_not_equal(expected, actual, message)` : Assertion de différence
- `assert_file_exists(file, message)` : Vérification d'existence de fichier
- `assert_dir_exists(dir, message)` : Vérification d'existence de répertoire
- `assert_port_open(port, message)` : Vérification de port ouvert
- `assert_command_exists(cmd, message)` : Vérification de commande disponible

**Exemple d'utilisation** :

```bash
#!/bin/bash
set -euo pipefail

source tests/utils/test_framework.sh

test_suite_start "Test des fonctions portables"

assert_equal "$(get_realpath /tmp)" "/tmp" "get_realpath fonctionne"
assert_command_exists "java" "Java est installé"
assert_port_open 9042 "HCD est démarré"

test_suite_end
```

##### 1.2.2 Créer Fixtures de Base

**Fichiers à créer dans `tests/fixtures/`** :

- `config/test_config.sh` : Configuration de test isolée
- `data/sample_data.json` : Données de test JSON
- `schemas/test_keyspace.cql` : Schéma CQL de test
- `scripts/test_helper.sh` : Scripts utilitaires pour tests

---

#### Phase 2 : Tests Unitaires (Jours 2-3)

**Objectif** : Créer tests unitaires pour fonctions critiques

##### 2.1 Tests pour `portable_functions.sh`

**Fichier** : `tests/unit/test_portable_functions.sh`

**Tests à créer** :

1. `test_get_realpath()` : Test de `get_realpath()` sur différents OS
2. `test_check_port()` : Test de `check_port()` avec ports ouverts/fermés
3. `test_kill_process()` : Test de `kill_process()` (mock)
4. `test_detect_os()` : Test de détection OS

**Exemple** :

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$ARKEA_HOME/tests/utils/test_framework.sh"
source "$ARKEA_HOME/scripts/utils/portable_functions.sh"

test_suite_start "Tests des fonctions portables"

# Test get_realpath
test_get_realpath() {
    local result
    result=$(get_realpath "$ARKEA_HOME")
    assert_equal "$result" "$ARKEA_HOME" "get_realpath retourne le bon chemin"
}

# Test check_port (port fermé)
test_check_port_closed() {
    local port=99999  # Port improbable
    if check_port "$port"; then
        echo "❌ Port $port devrait être fermé"
        return 1
    else
        echo "✅ Port $port correctement détecté comme fermé"
    fi
}

test_get_realpath
test_check_port_closed

test_suite_end
```

##### 2.2 Tests pour `.poc-config.sh`

**Fichier** : `tests/unit/test_poc_config.sh`

**Tests à créer** :

1. `test_arke_home_detection()` : Détection de ARKEA_HOME
2. `test_hcd_dir_detection()` : Détection de HCD_DIR
3. `test_spark_home_detection()` : Détection de SPARK_HOME
4. `test_kafka_home_detection()` : Détection de KAFKA_HOME
5. `test_default_values()` : Valeurs par défaut

##### 2.3 Tests pour Fonctions Utilitaires

**Fichiers à créer** :

- `tests/unit/test_didactique_functions.sh` : Tests des fonctions didactiques
- `tests/unit/test_validation_functions.sh` : Tests des fonctions de validation

---

#### Phase 3 : Tests d'Intégration (Jours 4-5)

**Objectif** : Créer tests d'intégration pour interactions entre composants

##### 3.1 Test HCD ↔ Spark

**Fichier** : `tests/integration/test_hcd_spark.sh`

**Tests à créer** :

1. `test_spark_connection()` : Connexion Spark à HCD
2. `test_spark_read()` : Lecture de données depuis HCD
3. `test_spark_write()` : Écriture de données vers HCD
4. `test_spark_query()` : Exécution de requêtes CQL via Spark

**Exemple** :

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$ARKEA_HOME/tests/utils/test_framework.sh"
source "$ARKEA_HOME/.poc-config.sh"

test_suite_start "Tests d'intégration HCD ↔ Spark"

test_spark_connection() {
    # Vérifier que Spark peut se connecter à HCD
    if [ -z "${SPARK_HOME:-}" ]; then
        echo "⚠️ SPARK_HOME non défini, test ignoré"
        return 0
    fi

    # Test de connexion via spark-shell
    local test_script="$ARKEA_HOME/tests/fixtures/scripts/test_spark_connection.scala"
    if "$SPARK_HOME/bin/spark-shell" --jars "$SPARK_CASSANDRA_CONNECTOR_JAR" < "$test_script" > /dev/null 2>&1; then
        echo "✅ Connexion Spark ↔ HCD réussie"
    else
        echo "❌ Échec de connexion Spark ↔ HCD"
        return 1
    fi
}

test_spark_connection

test_suite_end
```

##### 3.2 Test Kafka ↔ HCD Streaming

**Fichier** : `tests/integration/test_kafka_hcd_streaming.sh`

**Tests à créer** :

1. `test_kafka_topic_exists()` : Vérification de topic Kafka
2. `test_kafka_producer()` : Production de messages Kafka
3. `test_hcd_consumer()` : Consommation depuis Kafka vers HCD
4. `test_end_to_end_streaming()` : Pipeline complet Kafka → HCD

##### 3.3 Test POCs

**Fichiers à créer** :

- `tests/integration/test_bic_integration.sh` : Tests d'intégration BIC
- `tests/integration/test_domirama2_integration.sh` : Tests d'intégration domirama2
- `tests/integration/test_domiramaCatOps_integration.sh` : Tests d'intégration domiramaCatOps

---

#### Phase 4 : Tests E2E (Jours 6-7)

**Objectif** : Créer tests end-to-end pour scénarios complets

##### 4.1 Test Pipeline Complet

**Fichier** : `tests/e2e/test_kafka_hcd_pipeline.sh`

**Scénario** :

1. Démarrage HCD
2. Démarrage Kafka
3. Création topic Kafka
4. Production de données
5. Streaming Kafka → HCD
6. Vérification données dans HCD
7. Nettoyage

**Exemple** :

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$ARKEA_HOME/tests/utils/test_framework.sh"
source "$ARKEA_HOME/.poc-config.sh"

test_suite_start "Test E2E Pipeline Kafka → HCD"

# Setup
echo "📋 Setup : Démarrage HCD et Kafka..."
# ... code de setup ...

# Test
echo "🧪 Test : Pipeline complet..."
# ... code de test ...

# Cleanup
echo "🧹 Cleanup..."
# ... code de cleanup ...

test_suite_end
```

##### 4.2 Test Migration HBase → HCD

**Fichier** : `tests/e2e/test_migration_hbase_hcd.sh`

**Scénario** :

1. Préparation données HBase (mock)
2. Migration vers HCD
3. Vérification intégrité données
4. Vérification performance

---

### 1.3 Checklist de Mise en Œuvre

#### Jour 1 : Framework

- [ ] Créer `tests/utils/test_framework.sh`
- [ ] Créer fixtures de base dans `tests/fixtures/`
- [ ] Documenter framework dans `tests/README.md`

#### Jours 2-3 : Tests Unitaires

- [ ] Créer `tests/unit/test_portable_functions.sh` (10+ tests)
- [ ] Créer `tests/unit/test_poc_config.sh` (8+ tests)
- [ ] Créer `tests/unit/test_didactique_functions.sh` (5+ tests)
- [ ] Créer `tests/unit/test_validation_functions.sh` (5+ tests)

#### Jours 4-5 : Tests d'Intégration

- [ ] Créer `tests/integration/test_hcd_spark.sh` (4+ tests)
- [ ] Créer `tests/integration/test_kafka_hcd_streaming.sh` (4+ tests)
- [ ] Créer `tests/integration/test_bic_integration.sh` (3+ tests)
- [ ] Créer `tests/integration/test_domirama2_integration.sh` (3+ tests)
- [ ] Créer `tests/integration/test_domiramaCatOps_integration.sh` (3+ tests)

#### Jours 6-7 : Tests E2E

- [ ] Créer `tests/e2e/test_kafka_hcd_pipeline.sh` (scénario complet)
- [ ] Créer `tests/e2e/test_migration_hbase_hcd.sh` (scénario complet)
- [ ] Mettre à jour `tests/run_all_tests.sh` pour inclure E2E

---

## ⚙️ PRIORITÉ 3 : Enrichir CI/CD

**Score actuel** : **92/100**  
**Score cible** : **97/100**  
**Impact** : **+5 points**  
**Effort estimé** : **3-4 jours**

### 3.1 État Actuel

#### Points Forts ✅

- ✅ GitHub Actions configuré (`.github/workflows/test.yml`)
- ✅ Pre-commit hooks excellents (`.pre-commit-config.yaml`)
- ✅ Tests de syntaxe automatisés
- ✅ Tests de structure automatisés

#### Gaps Identifiés ⚠️

- ⚠️ **Tests fonctionnels** : Non automatisés dans CI/CD
- ⚠️ **Tests multi-OS** : Limités (Ubuntu uniquement)
- ⚠️ **Tests de régression** : Absents
- ⚠️ **Rapports de tests** : Non générés automatiquement
- ⚠️ **Notifications** : Absentes

---

### 3.2 Plan d'Action Détaillé

#### Phase 1 : Tests Automatisés dans CI/CD (Jour 1)

**Objectif** : Intégrer tests unitaires et d'intégration dans GitHub Actions

##### 3.2.1 Créer `.github/workflows/tests.yml`

**Nouveau workflow** :

```yaml
name: Tests Automatisés

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]
  schedule:
    - cron: '0 2 * * *'  # Tous les jours à 2h du matin

jobs:
  unit-tests:
    name: Tests Unitaires
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Bash
        run: echo "Bash version: $(bash --version)"

      - name: Setup Environment
        run: |
          source .poc-config.sh || true
          echo "ARKEA_HOME=$ARKEA_HOME" >> $GITHUB_ENV

      - name: Run Unit Tests
        run: |
          chmod +x tests/run_unit_tests.sh
          ./tests/run_unit_tests.sh

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: unit-test-results
          path: tests/results/

  integration-tests:
    name: Tests d'Intégration
    runs-on: ubuntu-latest
    needs: unit-tests

    services:
      cassandra:
        image: cassandra:4.0
        ports:
          - 9042:9042
        options: >-
          --health-cmd "cqlsh -e 'SELECT now() FROM system.local'"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Environment
        run: |
          source .poc-config.sh || true
          export HCD_HOST=localhost
          export HCD_PORT=9042

      - name: Wait for Cassandra
        run: |
          until cqlsh localhost 9042 -e 'SELECT now() FROM system.local'; do
            echo "Waiting for Cassandra..."
            sleep 2
          done

      - name: Run Integration Tests
        run: |
          chmod +x tests/run_integration_tests.sh
          ./tests/run_integration_tests.sh

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: integration-test-results
          path: tests/results/
```

##### 3.2.2 Améliorer `.github/workflows/test.yml`

**Ajouts** :

- Tests fonctionnels automatisés
- Génération de rapports
- Upload d'artifacts

---

#### Phase 2 : Tests Multi-OS (Jour 2)

**Objectif** : Tester sur macOS, Linux, Windows

##### 3.2.3 Créer `.github/workflows/test-multi-os.yml` (améliorer existant)

**Matrices** :

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest, windows-latest]
    shell: [bash]
```

**Tests par OS** :

- Ubuntu : Tests complets
- macOS : Tests complets (avec Homebrew)
- Windows : Tests WSL2

---

#### Phase 3 : Tests de Régression (Jour 3)

**Objectif** : Détecter régressions automatiquement

##### 3.3.1 Créer `.github/workflows/regression-tests.yml`

**Tests** :

- Comparaison avec version précédente
- Tests de performance (benchmarks)
- Tests de compatibilité

##### 3.3.2 Créer Script de Benchmark

**Fichier** : `tests/utils/benchmark.sh`

**Métriques** :

- Temps d'exécution des scripts
- Utilisation mémoire
- Performance requêtes HCD

---

#### Phase 4 : Rapports et Notifications (Jour 4)

**Objectif** : Générer rapports et notifier

##### 3.4.1 Génération de Rapports

**Outils** :

- `junit-xml` pour rapports JUnit
- `coverage` pour couverture de code
- Markdown pour rapports lisible

**Script** : `tests/utils/generate_report.sh`

##### 3.4.2 Notifications

**Channels** :

- GitHub Issues (échecs)
- Slack/Discord (optionnel)
- Email (optionnel)

---

### 3.3 Checklist de Mise en Œuvre

#### Jour 1 : Tests Automatisés

- [ ] Créer `.github/workflows/tests.yml`
- [ ] Intégrer tests unitaires dans CI/CD
- [ ] Intégrer tests d'intégration dans CI/CD
- [ ] Configurer services Docker (Cassandra, Kafka)

#### Jour 2 : Tests Multi-OS

- [ ] Améliorer `.github/workflows/test-multi-os.yml`
- [ ] Ajouter matrice macOS
- [ ] Ajouter matrice Windows (WSL2)
- [ ] Tester sur chaque OS

#### Jour 3 : Tests de Régression

- [ ] Créer `.github/workflows/regression-tests.yml`
- [ ] Créer `tests/utils/benchmark.sh`
- [ ] Configurer comparaison avec version précédente
- [ ] Documenter métriques

#### Jour 4 : Rapports et Notifications

- [ ] Créer `tests/utils/generate_report.sh`
- [ ] Configurer génération rapports JUnit
- [ ] Configurer notifications GitHub
- [ ] Documenter processus

---

## 📊 Métriques de Succès

### Priorité 1 : Tests

#### Métriques Quantitatives

- **Tests unitaires** : 30+ tests (actuellement 2)
- **Tests d'intégration** : 20+ tests (actuellement 1)
- **Tests E2E** : 2+ scénarios complets (actuellement 0)
- **Couverture** : 60%+ (actuellement non mesurée)

#### Métriques Qualitatives

- ✅ Tous les tests passent
- ✅ Tests exécutables en isolation
- ✅ Fixtures réutilisables
- ✅ Documentation complète

### Priorité 3 : CI/CD

#### Métriques Quantitatives

- **Workflows CI/CD** : 4+ workflows (actuellement 3)
- **Tests automatisés** : 50+ tests (actuellement syntaxe uniquement)
- **OS supportés** : 3 OS (actuellement 1)
- **Temps d'exécution** : < 30 min (actuellement < 10 min)

#### Métriques Qualitatives

- ✅ Tests exécutés automatiquement
- ✅ Rapports générés automatiquement
- ✅ Notifications configurées
- ✅ Tests de régression fonctionnels

---

## ⏱️ Timeline et Ressources

### Timeline

| Phase | Durée | Dates |
| ----- | ----- | ----- |
| **Priorité 1 - Phase 1** | 1 jour | Jour 1 |
| **Priorité 1 - Phase 2** | 2 jours | Jours 2-3 |
| **Priorité 1 - Phase 3** | 2 jours | Jours 4-5 |
| **Priorité 1 - Phase 4** | 2 jours | Jours 6-7 |
| **Priorité 3 - Phase 1** | 1 jour | Jour 8 |
| **Priorité 3 - Phase 2** | 1 jour | Jour 9 |
| **Priorité 3 - Phase 3** | 1 jour | Jour 10 |
| **Priorité 3 - Phase 4** | 1 jour | Jour 11 |
| **Total** | **11 jours** | |

### Ressources Nécessaires

#### Compétences

- ✅ Scripting Bash avancé
- ✅ GitHub Actions
- ✅ Docker (pour services de test)
- ✅ Tests automatisés

#### Outils

- ✅ GitHub Actions (gratuit)
- ✅ Docker (gratuit)
- ✅ ShellCheck (déjà installé)
- ✅ Pre-commit (déjà configuré)

#### Infrastructure

- ✅ GitHub (déjà configuré)
- ✅ Services Docker (Cassandra, Kafka)
- ⚠️ Environnement de test isolé (à créer)

---

## 📝 Exemples de Code

### Exemple 1 : Framework de Tests

Voir section 1.2.1 pour exemple complet de `test_framework.sh`

### Exemple 2 : Test Unitaire

Voir section 2.1 pour exemple complet de `test_portable_functions.sh`

### Exemple 3 : Test d'Intégration

Voir section 3.1 pour exemple complet de `test_hcd_spark.sh`

### Exemple 4 : Workflow GitHub Actions

Voir section 3.2.1 pour exemple complet de `.github/workflows/tests.yml`

---

## ✅ Validation

### Critères de Succès

#### Priorité 1

- ✅ 30+ tests unitaires créés et passent
- ✅ 20+ tests d'intégration créés et passent
- ✅ 2+ tests E2E créés et passent
- ✅ Framework de tests réutilisable
- ✅ Fixtures créées et documentées

#### Priorité 3

- ✅ Tests automatisés dans CI/CD
- ✅ Tests multi-OS fonctionnels
- ✅ Tests de régression configurés
- ✅ Rapports générés automatiquement
- ✅ Notifications configurées

### Score Cible

- **Priorité 1** : 82/100 → **90/100** (+8 points)
- **Priorité 3** : 92/100 → **97/100** (+5 points)
- **Score Global** : 91.5/100 → **94-95/100** (+2.5-3.5 points)

---

**Date** : 2025-12-02  
**Version** : 1.0.0  
**Statut** : ✅ **Plan d'action complet**
