#!/usr/bin/env bash
# ARKEA PoC configuration (dual-leg compatible defaults)
# Supports:
#   - podman: Cassandra 5.0 OSS stack (mapped host ports)
#   - binary: HCD tarball stack (local binary ports)

# Resolve project root from this file location
ARKEA_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ARKEA_HOME

# Local runtime directories
export BINAIRE_DIR="${BINAIRE_DIR:-$ARKEA_HOME/binaire}"
export SOFTWARE_DIR="${SOFTWARE_DIR:-$ARKEA_HOME/software}"
export HCD_DATA_DIR="${HCD_DATA_DIR:-$ARKEA_HOME/hcd-data}"

# Common component versions
export SPARK_VERSION="${SPARK_VERSION:-3.5.1}"

# Runtime leg selector: podman | binary
export ARKEA_LEG="${ARKEA_LEG:-podman}"

case "$ARKEA_LEG" in
    podman)
        export HCD_VERSION="${HCD_VERSION:-5.0.6}"
        export HCD_HOST="${HCD_HOST:-localhost}"
        export HCD_PORT="${HCD_PORT:-9102}"  # Podman host -> container 9042
        export KAFKA_HOST="${KAFKA_HOST:-localhost}"
        export KAFKA_PORT="${KAFKA_PORT:-9192}"  # Podman host -> container 9092
        ;;
    binary)
        export HCD_VERSION="${HCD_VERSION:-1.2.3}"
        export HCD_HOST="${HCD_HOST:-localhost}"
        export HCD_PORT="${HCD_PORT:-9042}"
        export KAFKA_HOST="${KAFKA_HOST:-localhost}"
        export KAFKA_PORT="${KAFKA_PORT:-9092}"
        ;;
    *)
        echo "⚠️  ARKEA_LEG invalide: '$ARKEA_LEG' (valeurs: podman|binary). Fallback sur podman." >&2
        export ARKEA_LEG="podman"
        export HCD_VERSION="${HCD_VERSION:-5.0.6}"
        export HCD_HOST="${HCD_HOST:-localhost}"
        export HCD_PORT="${HCD_PORT:-9102}"
        export KAFKA_HOST="${KAFKA_HOST:-localhost}"
        export KAFKA_PORT="${KAFKA_PORT:-9192}"
        ;;
esac
