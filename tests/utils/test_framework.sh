#!/bin/bash
# =============================================================================
# Framework de Tests pour ARKEA
# =============================================================================
# Date : 2025-12-02
# Usage : source tests/utils/test_framework.sh
# Objectif : Framework réutilisable pour tests unitaires et d'intégration
# =============================================================================

# Variables globales
TEST_SUITE_NAME=""
TEST_PASSED=0
TEST_FAILED=0
TEST_TOTAL=0
TEST_START_TIME=0

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# FONCTION : Début d'une suite de tests
# =============================================================================
#
# Usage: test_suite_start <name>
#
test_suite_start() {
    TEST_SUITE_NAME="$1"
    TEST_PASSED=0
    TEST_FAILED=0
    TEST_TOTAL=0
    TEST_START_TIME=$(date +%s)

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🧪 Suite de Tests : $TEST_SUITE_NAME"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# =============================================================================
# FONCTION : Fin d'une suite de tests
# =============================================================================
#
# Usage: test_suite_end
#
test_suite_end() {
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - TEST_START_TIME))

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Résumé : $TEST_SUITE_NAME"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Tests passés  : $TEST_PASSED"
    echo "❌ Tests échoués : $TEST_FAILED"
    echo "📋 Tests totaux  : $TEST_TOTAL"
    echo "⏱️  Durée        : ${duration}s"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [ $TEST_FAILED -eq 0 ]; then
        echo -e "${GREEN}✅ Tous les tests sont passés !${NC}"
        return 0
    else
        echo -e "${RED}❌ $TEST_FAILED test(s) ont échoué${NC}"
        return 1
    fi
}

# =============================================================================
# FONCTION : Assertion d'égalité
# =============================================================================
#
# Usage: assert_equal <expected> <actual> <message>
#
assert_equal() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    TEST_TOTAL=$((TEST_TOTAL + 1))

    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}✅${NC} $message"
        TEST_PASSED=$((TEST_PASSED + 1))
        return 0
    else
        echo -e "${RED}❌${NC} $message"
        echo "   Expected: $expected"
        echo "   Actual  : $actual"
        TEST_FAILED=$((TEST_FAILED + 1))
        return 1
    fi
}

# =============================================================================
# FONCTION : Assertion de différence
# =============================================================================
#
# Usage: assert_not_equal <expected> <actual> <message>
#
assert_not_equal() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    TEST_TOTAL=$((TEST_TOTAL + 1))

    if [ "$expected" != "$actual" ]; then
        echo -e "${GREEN}✅${NC} $message"
        TEST_PASSED=$((TEST_PASSED + 1))
        return 0
    else
        echo -e "${RED}❌${NC} $message"
        echo "   Values should be different but both are: $expected"
        TEST_FAILED=$((TEST_FAILED + 1))
        return 1
    fi
}

# =============================================================================
# FONCTION : Vérification d'existence de fichier
# =============================================================================
#
# Usage: assert_file_exists <file> <message>
#
assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist: $file}"

    TEST_TOTAL=$((TEST_TOTAL + 1))

    if [ -f "$file" ]; then
        echo -e "${GREEN}✅${NC} $message"
        TEST_PASSED=$((TEST_PASSED + 1))
        return 0
    else
        echo -e "${RED}❌${NC} $message"
        echo "   File not found: $file"
        TEST_FAILED=$((TEST_FAILED + 1))
        return 1
    fi
}

# =============================================================================
# FONCTION : Vérification d'existence de répertoire
# =============================================================================
#
# Usage: assert_dir_exists <dir> <message>
#
assert_dir_exists() {
    local dir="$1"
    local message="${2:-Directory should exist: $dir}"

    TEST_TOTAL=$((TEST_TOTAL + 1))

    if [ -d "$dir" ]; then
        echo -e "${GREEN}✅${NC} $message"
        TEST_PASSED=$((TEST_PASSED + 1))
        return 0
    else
        echo -e "${RED}❌${NC} $message"
        echo "   Directory not found: $dir"
        TEST_FAILED=$((TEST_FAILED + 1))
        return 1
    fi
}

# =============================================================================
# FONCTION : Vérification de port ouvert
# =============================================================================
#
# Usage: assert_port_open <port> <message>
#
assert_port_open() {
    local port="$1"
    local message="${2:-Port should be open: $port}"

    TEST_TOTAL=$((TEST_TOTAL + 1))

    # Vérifier si le port est utilisé
    if command -v lsof &> /dev/null; then
        if lsof -Pi :"$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo -e "${GREEN}✅${NC} $message"
            TEST_PASSED=$((TEST_PASSED + 1))
            return 0
        fi
    elif command -v nc &> /dev/null; then
        if nc -z localhost "$port" >/dev/null 2>&1; then
            echo -e "${GREEN}✅${NC} $message"
            TEST_PASSED=$((TEST_PASSED + 1))
            return 0
        fi
    fi

    echo -e "${RED}❌${NC} $message"
    echo "   Port $port is not open"
    TEST_FAILED=$((TEST_FAILED + 1))
    return 1
}

# =============================================================================
# FONCTION : Vérification de commande disponible
# =============================================================================
#
# Usage: assert_command_exists <cmd> <message>
#
assert_command_exists() {
    local cmd="$1"
    local message="${2:-Command should exist: $cmd}"

    TEST_TOTAL=$((TEST_TOTAL + 1))

    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}✅${NC} $message"
        TEST_PASSED=$((TEST_PASSED + 1))
        return 0
    else
        echo -e "${RED}❌${NC} $message"
        echo "   Command not found: $cmd"
        TEST_FAILED=$((TEST_FAILED + 1))
        return 1
    fi
}

# =============================================================================
# FONCTION : Vérification de variable définie
# =============================================================================
#
# Usage: assert_var_defined <var_name> <message>
#
assert_var_defined() {
    local var_name="$1"
    local message="${2:-Variable should be defined: $var_name}"

    TEST_TOTAL=$((TEST_TOTAL + 1))

    # Vérifier si la variable est définie et non vide
    if [ -n "${!var_name:-}" ]; then
        echo -e "${GREEN}✅${NC} $message"
        TEST_PASSED=$((TEST_PASSED + 1))
        return 0
    else
        echo -e "${RED}❌${NC} $message"
        echo "   Variable not defined or empty: $var_name"
        TEST_FAILED=$((TEST_FAILED + 1))
        return 1
    fi
}

# =============================================================================
# FONCTION : Vérification de contenu de fichier
# =============================================================================
#
# Usage: assert_file_contains <file> <pattern> <message>
#
assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local message="${3:-File should contain pattern: $pattern}"

    TEST_TOTAL=$((TEST_TOTAL + 1))

    if [ -f "$file" ] && grep -q "$pattern" "$file" 2>/dev/null; then
        echo -e "${GREEN}✅${NC} $message"
        TEST_PASSED=$((TEST_PASSED + 1))
        return 0
    else
        echo -e "${RED}❌${NC} $message"
        echo "   Pattern not found in file: $file"
        TEST_FAILED=$((TEST_FAILED + 1))
        return 1
    fi
}

# =============================================================================
# FONCTION : Exécution de test avec gestion d'erreur
# =============================================================================
#
# Usage: run_test <test_function> <description>
#
run_test() {
    local test_func="$1"
    local description="${2:-Running test: $test_func}"

    echo -e "${BLUE}▶${NC} $description"

    if "$test_func"; then
        return 0
    else
        echo -e "${YELLOW}⚠${NC} Test failed: $description"
        return 1
    fi
}
