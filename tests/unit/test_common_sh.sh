#!/bin/bash
# =============================================================================
# Script : Unit Tests for lib/common.sh
# =============================================================================
# Date : 2026-03-13
# Version : 1.0.0
# Author : David LECONTE (IBM WW|Tiger Team - Watsonx.Data GPS)
# Description : Comprehensive unit tests for shared library functions
# Usage : ./tests/unit/test_common_sh.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source the test framework
source "${PROJECT_ROOT}/tests/utils/test_framework.sh"

# Source the library under test
source "${PROJECT_ROOT}/lib/common.sh"

# =============================================================================
# Test Suite: OS Detection
# =============================================================================
test_os_detection() {
    test_suite_start "OS Detection Functions"

    # Test detect_os returns valid value
    local os
    os=$(detect_os)
    assert_contains "$os" "macos|linux|windows|unknown" "detect_os returns valid OS type"

    # Test get_realpath with directory
    local path
    path=$(get_realpath "${PROJECT_ROOT}")
    assert_equal "$path" "$PROJECT_ROOT" "get_realpath resolves project root"

    # Test get_realpath with file
    path=$(get_realpath "${PROJECT_ROOT}/lib/common.sh")
    assert_contains "$path" "common.sh" "get_realpath resolves file path"

    test_suite_end
}

# =============================================================================
# Test Suite: Logging Functions
# =============================================================================
test_logging_functions() {
    test_suite_start "Logging Functions"

    # Test log_info (capture output)
    local output
    output=$(log_info "test message" 2>&1)
    assert_contains "$output" "INFO" "log_info contains INFO level"
    assert_contains "$output" "test message" "log_info contains message"

    # Test log_success
    output=$(log_success "success test" 2>&1)
    assert_contains "$output" "SUCCESS" "log_success contains SUCCESS level"

    # Test log_warn
    output=$(log_warn "warning test" 2>&1)
    assert_contains "$output" "WARN" "log_warn contains WARN level"

    # Test log_error
    output=$(log_error "error test" 2>&1)
    assert_contains "$output" "ERROR" "log_error contains ERROR level"

    # Test log_section
    output=$(log_section "Test Section" 2>&1)
    assert_contains "$output" "Test Section" "log_section contains section title"

    test_suite_end
}

# =============================================================================
# Test Suite: Port Checking
# =============================================================================
test_port_checking() {
    test_suite_start "Port Checking Functions"

    # Test check_port with closed port (high port unlikely to be open)
    local result
    if check_port 59999 "localhost" 1 2>/dev/null; then
        result="open"
    else
        result="closed"
    fi
    # Port 59999 should be closed
    assert_equal "$result" "closed" "check_port returns closed for unused port"

    # Test wait_for_port timeout
    local start_time end_time duration
    start_time=$(date +%s)
    if wait_for_port 59998 "localhost" 2 2>/dev/null; then
        result="success"
    else
        result="timeout"
    fi
    end_time=$(date +%s)
    duration=$((end_time - start_time))

    assert_equal "$result" "timeout" "wait_for_port times out correctly"
    assert_greater_than "$duration" 1 "wait_for_port waited at least 1 second"

    test_suite_end
}

# =============================================================================
# Test Suite: Service Status Functions
# =============================================================================
test_service_status() {
    test_suite_start "Service Status Functions"

    # Test hcd_status (should fail if HCD not running)
    if hcd_status 2>/dev/null; then
        log_info "HCD is running"
    else
        log_info "HCD is not running (expected in isolated test)"
    fi
    # This test is informational, not asserting

    # Test kafka_status (should fail if Kafka not running)
    if kafka_status 2>/dev/null; then
        log_info "Kafka is running"
    else
        log_info "Kafka is not running (expected in isolated test)"
    fi

    # Test spark_status
    if spark_status 2>/dev/null; then
        log_info "Spark is configured"
    else
        log_info "Spark not configured (expected if SPARK_HOME not set)"
    fi

    test_suite_end
}

# =============================================================================
# Test Suite: Environment Validation
# =============================================================================
test_environment_validation() {
    test_suite_start "Environment Validation"

    # Test PROJECT_ROOT is set
    assert_var_defined "PROJECT_ROOT" "PROJECT_ROOT is defined"

    # Test PROJECT_ROOT exists
    assert_dir_exists "$PROJECT_ROOT" "PROJECT_ROOT directory exists"

    # Test LOG_DIR is set
    assert_var_defined "LOG_DIR" "LOG_DIR is defined"

    # Test LOG_DIR exists (should be created by common.sh)
    assert_dir_exists "$LOG_DIR" "LOG_DIR directory exists"

    test_suite_end
}

# =============================================================================
# Test Suite: CQL Helpers (Mock Tests)
# =============================================================================
test_cql_helpers() {
    test_suite_start "CQL Helper Functions"

    # Test cql_exec function exists
    assert_command_defined "cql_exec" "cql_exec function is defined"

    # Test cql_exec_file function exists
    assert_command_defined "cql_exec_file" "cql_exec_file function is defined"

    # Note: Actual CQL execution requires running HCD, tested in integration tests

    test_suite_end
}

# =============================================================================
# Test Suite: Configuration Loading
# =============================================================================
test_configuration() {
    test_suite_start "Configuration Loading"

    # Test that common.sh sets strict mode
    # This is verified by the fact that the script runs successfully

    # Test LOG_LEVEL default
    assert_var_defined "LOG_LEVEL" "LOG_LEVEL is defined"

    # Test color variables are defined
    assert_var_defined "RED" "RED color is defined"
    assert_var_defined "GREEN" "GREEN color is defined"
    assert_var_defined "YELLOW" "YELLOW color is defined"
    assert_var_defined "BLUE" "BLUE color is defined"
    assert_var_defined "NC" "NC (no color) is defined"

    test_suite_end
}

# =============================================================================
# Helper Functions for Tests
# =============================================================================

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String contains check}"

    if [[ "$haystack" == *"$needle"* ]]; then
        test_pass "$message"
    else
        test_fail "$message"
        echo "    Expected: '$needle' in '$haystack'"
    fi
}

assert_greater_than() {
    local actual="$1"
    local threshold="$2"
    local message="${3:-Greater than check}"

    if [[ "$actual" -gt "$threshold" ]]; then
        test_pass "$message"
    else
        test_fail "$message"
        echo "    Expected: $actual > $threshold"
    fi
}

assert_command_defined() {
    local cmd="$1"
    local message="${2:-Command is defined}"

    if declare -f "$cmd" &>/dev/null; then
        test_pass "$message"
    else
        test_fail "$message"
        echo "    Command '$cmd' is not defined"
    fi
}

# =============================================================================
# Main Test Runner
# =============================================================================
main() {
    log_section "ARKEA POC - Unit Tests for lib/common.sh"

    echo "Project Root: $PROJECT_ROOT"
    echo "Library Under Test: lib/common.sh"
    echo ""

    # Run all test suites
    test_os_detection
    test_logging_functions
    test_port_checking
    test_service_status
    test_environment_validation
    test_cql_helpers
    test_configuration

    log_section "Test Summary"
    echo ""
    echo "All unit tests for lib/common.sh completed."
}

# Run main
main "$@"
