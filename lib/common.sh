#!/bin/bash
# =============================================================================
# ARKEA Common Library - Shared Functions for All POCs
# =============================================================================
# Date : 2025-03-13
# Version : 1.0.0
# Author : David LECONTE (IBM WW|Tiger Team - Watsonx.Data GPS)
# Description : Centralized library for cross-platform compatibility,
#               logging, validation, and HCD/Spark/Kafka operations.
# Usage : source lib/common.sh
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

# Resolve library location
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${LIB_DIR}/.." && pwd)"

# Source the main config if available
if [[ -f "${PROJECT_ROOT}/.poc-config.sh" ]]; then
    source "${PROJECT_ROOT}/.poc-config.sh"
fi

# Logging configuration
LOG_LEVEL="${LOG_LEVEL:-INFO}"
LOG_DIR="${LOG_DIR:-${PROJECT_ROOT}/logs}"
mkdir -p "${LOG_DIR}" 2>/dev/null || true

# =============================================================================
# OS DETECTION (Portable)
# =============================================================================

detect_os() {
    case "$OSTYPE" in
        darwin*)      echo "macos" ;;
        linux-gnu*)   echo "linux" ;;
        linux*)       echo "linux" ;;
        msys*)        echo "windows" ;;
        cygwin*)      echo "windows" ;;
        *)            echo "unknown" ;;
    esac
}

get_realpath() {
    local path="$1"
    if [[ -d "$path" ]]; then
        (cd "$path" && pwd)
    elif [[ -f "$path" ]]; then
        local dir
        dir="$(cd "$(dirname "$path")" && pwd)"
        echo "$dir/$(basename "$path")"
    else
        echo "$path"
    fi
}

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

log_debug() { [[ "$LOG_LEVEL" == "DEBUG" ]] && echo -e "${CYAN}[DEBUG]${NC} $*" || true; }
log_info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }

log_section() {
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  $*${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# =============================================================================
# PORT CHECKING (Portable)
# =============================================================================

check_port() {
    local port="$1"
    local host="${2:-localhost}"
    local timeout="${3:-2}"

    if command -v nc &>/dev/null; then
        nc -z -w "$timeout" "$host" "$port" 2>/dev/null
    elif command -v python3 &>/dev/null; then
        python3 -c "
import socket
s = socket.socket()
s.settimeout($timeout)
result = s.connect_ex(('$host', $port))
s.close()
exit(result)
" 2>/dev/null
    else
        # Fallback to /dev/tcp if available
        (echo >"/dev/tcp/$host/$port") 2>/dev/null
    fi
}

wait_for_port() {
    local port="$1"
    local host="${2:-localhost}"
    local max_wait="${3:-30}"
    local count=0

    log_info "Waiting for $host:$port..."
    while ! check_port "$port" "$host"; do
        count=$((count + 1))
        if [[ $count -ge $max_wait ]]; then
            log_error "Timeout waiting for $host:$port"
            return 1
        fi
        sleep 1
    done
    log_success "$host:$port is available"
}

# =============================================================================
# SERVICE MANAGEMENT
# =============================================================================

hcd_status() {
    if check_port "${HCD_PORT:-9042}" "${HCD_HOST:-localhost}"; then
        log_success "HCD is running on ${HCD_HOST:-localhost}:${HCD_PORT:-9042}"
        return 0
    else
        log_warn "HCD is not running"
        return 1
    fi
}

kafka_status() {
    if check_port "${KAFKA_PORT:-9092}" "${KAFKA_HOST:-localhost}"; then
        log_success "Kafka is running on ${KAFKA_HOST:-localhost}:${KAFKA_PORT:-9092}"
        return 0
    else
        log_warn "Kafka is not running"
        return 1
    fi
}

spark_status() {
    if [[ -n "${SPARK_HOME:-}" ]] && [[ -d "$SPARK_HOME" ]]; then
        log_success "Spark is configured at $SPARK_HOME"
        return 0
    else
        log_warn "SPARK_HOME is not set or invalid"
        return 1
    fi
}

# =============================================================================
# CQL HELPERS
# =============================================================================

cql_exec() {
    local query="$1"
    local host="${HCD_HOST:-localhost}"
    local port="${HCD_PORT:-9042}"

    cqlsh "$host" "$port" -e "$query"
}

cql_exec_file() {
    local file="$1"
    local host="${HCD_HOST:-localhost}"
    local port="${HCD_PORT:-9042}"

    cqlsh "$host" "$port" -f "$file"
}

# =============================================================================
# VALIDATION
# =============================================================================

validate_env() {
    local missing=0

    log_section "Validating Environment"

    # Check required directories
    for dir in "$PROJECT_ROOT" "${BINAIRE_DIR:-}" "${SOFTWARE_DIR:-}"; do
        if [[ -n "$dir" ]] && [[ ! -d "$dir" ]]; then
            log_warn "Directory not found: $dir"
        fi
    done

    # Check required tools
    for cmd in cqlsh python3 java; do
        if command -v "$cmd" &>/dev/null; then
            log_success "Found: $cmd"
        else
            log_warn "Missing: $cmd"
        fi
    done

    # Check services
    hcd_status || true
    kafka_status || true
    spark_status || true

    return $missing
}

# =============================================================================
# INITIALIZATION
# =============================================================================

# Auto-initialize if sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    log_debug "Loaded lib/common.sh from ${BASH_SOURCE[1]}"
fi
