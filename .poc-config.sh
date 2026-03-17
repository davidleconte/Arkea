#!/usr/bin/env bash
# ARKEA PoC configuration (minimal compatible defaults)
# Updated for Cassandra 5.0 OSS (Podman mode)

# Resolve project root from this file location
ARKEA_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ARKEA_HOME

# Local runtime directories
export BINAIRE_DIR="${BINAIRE_DIR:-$ARKEA_HOME/binaire}"
export SOFTWARE_DIR="${SOFTWARE_DIR:-$ARKEA_HOME/software}"
export HCD_DATA_DIR="${HCD_DATA_DIR:-$ARKEA_HOME/hcd-data}"

# Component versions (for binary mode - OSS5.0 uses Podman)
export HCD_VERSION="${HCD_VERSION:-5.0.6}"
export SPARK_VERSION="${SPARK_VERSION:-3.5.1}"

# Connectivity defaults (Podman-mapped ports for external access)
export HCD_HOST="${HCD_HOST:-localhost}"
export HCD_PORT="${HCD_PORT:-9102}"  # Podman: 9102 -> container 9042
export KAFKA_HOST="${KAFKA_HOST:-localhost}"
export KAFKA_PORT="${KAFKA_PORT:-9192}"  # Podman: 9192 -> container 9092
