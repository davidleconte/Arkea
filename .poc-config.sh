#!/usr/bin/env bash
# ARKEA PoC configuration (minimal compatible defaults)

# Resolve project root from this file location
ARKEA_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ARKEA_HOME

# Local runtime directories
export BINAIRE_DIR="${BINAIRE_DIR:-$ARKEA_HOME/binaire}"
export SOFTWARE_DIR="${SOFTWARE_DIR:-$ARKEA_HOME/software}"
export HCD_DATA_DIR="${HCD_DATA_DIR:-$ARKEA_HOME/hcd-data}"

# Component versions (kept as defaults, can be overridden by env)
export HCD_VERSION="${HCD_VERSION:-1.2.3}"
export SPARK_VERSION="${SPARK_VERSION:-3.5.1}"

# Connectivity defaults
export HCD_HOST="${HCD_HOST:-localhost}"
export HCD_PORT="${HCD_PORT:-9042}"
export KAFKA_HOST="${KAFKA_HOST:-localhost}"
export KAFKA_PORT="${KAFKA_PORT:-9092}"
