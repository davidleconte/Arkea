#!/bin/bash
# =============================================================================
# OSS5.0 Commons - Fonctions utilitaires pour Cassandra 5.0 OSS (Podman)
# =============================================================================
# Usage: source utils/oss5_commons.sh
# =============================================================================

# Détecter si on utilise Podman ou Binary
detect_container_mode() {
    if [ "${HCD_DIR:-}" = "podman" ] || [ -z "${HCD_DIR:-}" ]; then
        echo "podman"
    else
        echo "binary"
    fi
}

# Configuration cqlsh selon le mode
setup_cqlsh() {
    local mode=$(detect_container_mode)

    if [ "$mode" = "podman" ]; then
        # Vérifier que le container est running
        if ! podman ps --filter "name=arkea-hcd" --format "{{.Names}}" 2>/dev/null | grep -q "arkea-hcd"; then
            echo "ERROR: Container arkea-hcd n'est pas en cours d'exécution"
            echo "Exécutez: make demo"
            return 1
        fi
        export CQLSH_CMD="podman exec arkea-hcd cqlsh localhost 9042"
    else
        local cqlsh_bin="${HCD_DIR:-}/bin/cqlsh"
        export CQLSH_CMD="$cqlsh_bin ${HCD_HOST:-localhost} ${HCD_PORT:-9042}"
    fi
}

# Exécuter une commande cqlsh
run_cqlsh() {
    local mode=$(detect_container_mode)

    if [ "$mode" = "podman" ]; then
        # Pour Podman: copier le fichier si c'est un fichier
        if [ -f "$1" ]; then
            local filename=$(basename "$1")
            podman cp "$1" arkea-hcd:/tmp/$filename
            podman exec arkea-hcd cqlsh localhost 9042 -f /tmp/$filename
        else
            # CQL statement inline
            podman exec arkea-hcd cqlsh localhost 9042 -e "$1"
        fi
    else
        # Binary mode
        if [ -f "$1" ]; then
            ${HCD_DIR:-}/bin/cqlsh ${HCD_HOST:-localhost} ${HCD_PORT:-9042} -f "$1"
        else
            ${HCD_DIR:-}/bin/cqlsh ${HCD_HOST:-localhost} ${HCD_PORT:-9042} -e "$1"
        fi
    fi
}

# Exécuter une commande Kafka
run_kafka() {
    local mode=$(detect_container_mode)
    local cmd="$1"
    shift

    if [ "$mode" = "podman" ]; then
        podman exec arkea-kafka /opt/kafka/bin/$cmd --bootstrap-server localhost:9092 "$@"
    else
        ${KAFKA_HOME:-}/bin/$cmd --bootstrap-server localhost:9092 "$@"
    fi
}

# Vérifier les services
check_services() {
    local mode=$(detect_container_mode)

    if [ "$mode" = "podman" ]; then
        echo "=== Services Podman ==="
        podman ps --filter "name=arkea" --format "{{.Names}}\t{{.Status}}"
    else
        echo "=== Services Binaires ==="
        echo "HCD: ${HCD_DIR:-non configuré}"
        echo "Spark: ${SPARK_HOME:-non configuré}"
    fi
}
