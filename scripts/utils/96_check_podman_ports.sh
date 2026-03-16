#!/bin/bash
set -euo pipefail
# =============================================================================
# Script : Pre-Flight Port Conflict Detection
# =============================================================================
# Date : 2026-03-13
# POC : global
# Description : Check for port conflicts before starting ARKEA containers
# Usage : ./scripts/utils/96_check_podman_ports.sh
# =============================================================================
# ⚠️ IMPERATIVE: See PODMAN_RULES.md for isolation requirements
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source common library
source "${PROJECT_ROOT}/lib/common.sh"

# =============================================================================
# ARKEA Port Allocation (Base: 9100)
# =============================================================================
# See PODMAN_RULES.md for full allocation table

# Use indexed array for port definitions (compatible with set -u)
ARKEA_PORTS=(
    "HCD_CQL:9102:9042:CQL Native Transport"
    "HCD_INTRA:9100:7000:Intra-node communication"
    "HCD_INTRA_TLS:9101:7001:Intra-node TLS"
    "HCD_SOLR:9045:8983:Solr HTTP"
    "HCD_GRAPH:9182:8182:Graph API"
    "SPARK_MASTER:9177:7077:Spark Master"
    "SPARK_UI:9180:8080:Spark Web UI"
    "SPARK_WORKER_UI:9181:8081:Spark Worker UI"
    "KAFKA:9192:9092:Kafka Broker"
    "KAFKA_CONTROLLER:9193:9093:Kafka Controller"
    "KAFKA_EXTERNAL:9194:9094:Kafka External"
    "KAFKA_UI:9190:8080:Kafka UI"
)

# Ports that are MANDATORY to check
MANDATORY_PORTS="9102 9045 9180 9192"

# =============================================================================
# Functions
# =============================================================================

check_port() {
    local port="$1"
    local host="${2:-localhost}"

    if lsof -i :"$port" >/dev/null 2>&1; then
        return 1  # Port in use
    fi
    return 0  # Port available
}

get_port_user() {
    local port="$1"
    lsof -i :"$port" 2>/dev/null | tail -1 || echo "Unknown"
}

check_all_ports() {
    local conflicts=0
    local conflict_list=""

    log_section "ARKEA Port Conflict Detection"

    echo "Checking ARKEA port allocation (Base: 9100)..."
    echo ""

    # Print header
    printf "%-20s %-12s %-15s %-10s\n" "Service" "Host Port" "Status" "Note"
    printf "%-20s %-12s %-15s %-10s\n" "-------" "---------" "------" "----"

    # Check each port
    for entry in "${ARKEA_PORTS[@]}"; do
        IFS=':' read -r service host_port container_port description <<< "$entry"

        if check_port "$host_port"; then
            printf "%-20s %-12s \033[32m%-15s\033[0m %-10s\n" "$service" "$host_port" "✅ Available" "$description"
        else
            printf "%-20s %-12s \033[31m%-15s\033[0m %-10s\n" "$service" "$host_port" "❌ IN USE" "$description"
            conflicts=$((conflicts + 1))
            conflict_list="${conflict_list}\n  - ${service}: port ${host_port} ($(get_port_user "$host_port"))"
        fi
    done

    echo ""

    # Summary
    if [[ $conflicts -eq 0 ]]; then
        log_success "All ARKEA ports are available!"
        echo ""
        echo "Ready to start containers with:"
        echo "  podman-compose up -d"
        return 0
    else
        log_error "$conflicts port conflict(s) detected!"
        echo -e "$conflict_list"
        echo ""
        echo "⚠️  Resolution options:"
        echo "  1. Stop conflicting services"
        echo "  2. Use alternative ports (set environment variables):"
        echo "     export HCD_CQL_PORT=9112"
        echo "     export KAFKA_PORT=9292"
        echo "     podman-compose up -d"
        echo ""
        echo "  3. Check what's using the port:"
        echo "     lsof -i :<port>"
        return 1
    fi
}

check_podman_machine() {
    log_section "Podman Machine Status"

    if podman machine ls 2>/dev/null | grep -q "podman-wxd"; then
        log_success "podman-wxd machine exists"

        # Check if running
        local status
        status=$(podman machine ls --format "{{.Name}}: {{.Running}}" 2>/dev/null | grep "podman-wxd" || echo "Unknown")
        echo "  Status: $status"
        return 0
    else
        log_error "podman-wxd machine not found!"
        echo "  This machine is required. DO NOT create a new one."
        echo "  Contact infrastructure team if machine is missing."
        return 1
    fi
}

check_existing_projects() {
    log_section "Existing Projects (DO NOT MODIFY)"

    local pod_count
    pod_count=$(podman pod ps --format "{{.Name}}" 2>/dev/null | grep -cv "arkea")

    if [[ "$pod_count" -gt 0 ]]; then
        log_warn "Other projects are running on this machine"
        echo ""
        echo "Existing pods:"
        podman pod ps --format "  - {{.Name}} ({{.Status}})" 2>/dev/null | grep -v "arkea" || true
        echo ""
        echo "⚠️  IMPERATIVE: Do NOT stop, remove, or modify these pods!"
    else
        log_info "No other projects detected"
    fi
}

check_arkea_network() {
    log_section "ARKEA Network Status"

    local network_exists
    network_exists=$(podman network ls --filter "name=arkea-network" --format "{{.Name}}" 2>/dev/null || echo "")

    if [[ -n "$network_exists" ]]; then
        log_success "arkea-network exists"
        local subnet
        subnet=$(podman network inspect arkea-network --format '{{(index .IPAM.Config 0).Subnet}}' 2>/dev/null || echo "unknown")
        echo "  Subnet: $subnet"
        echo "  Expected: 10.89.10.0/24"
    else
        log_warn "arkea-network does not exist"
        echo "  Will be created automatically by podman-compose"
        echo "  Or create manually:"
        echo "    podman network create --subnet=10.89.10.0/24 --label project=arkea arkea-network"
    fi
}

check_arkea_resources() {
    log_section "ARKEA Resources Status"

    echo "ARKEA pods:"
    local arkea_pods
    arkea_pods=$(podman pod ps --filter "label=project=arkea" --format "  - {{.Name}} ({{.Status}})" 2>/dev/null || echo "  None")
    echo "$arkea_pods"

    echo ""
    echo "ARKEA volumes:"
    local arkea_volumes
    arkea_volumes=$(podman volume ls --filter "label=project=arkea" --format "  - {{.Name}}" 2>/dev/null || echo "  None")
    echo "$arkea_volumes"

    echo ""
    echo "ARKEA networks:"
    local arkea_networks
    arkea_networks=$(podman network ls --filter "label=project=arkea" --format "  - {{.Name}}" 2>/dev/null || echo "  None")
    echo "$arkea_networks"
}

# =============================================================================
# Main
# =============================================================================

main() {
    log_section "ARKEA POC - Pre-Flight Checks"
    echo "⚠️  See PODMAN_RULES.md for mandatory compliance requirements"
    echo ""

    # 1. Check Podman machine
    check_podman_machine || exit 1
    echo ""

    # 2. Check existing projects
    check_existing_projects
    echo ""

    # 3. Check ARKEA network
    check_arkea_network
    echo ""

    # 4. Check ARKEA resources
    check_arkea_resources
    echo ""

    # 4. Check port conflicts
    check_all_ports
    local port_result=$?

    echo ""
    log_section "Pre-Flight Summary"

    if [[ $port_result -eq 0 ]]; then
        log_success "All checks passed - ready to proceed"
        echo ""
        echo "Next steps:"
        echo "  1. Start services: podman-compose up -d"
        echo "  2. Check status:   podman ps --filter 'label=project=arkea'"
        echo "  3. View logs:      podman logs arkea-hcd"
    else
        log_error "Port conflicts detected - resolve before proceeding"
        exit 1
    fi
}

# Run main
main "$@"
