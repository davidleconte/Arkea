#!/bin/bash
set -euo pipefail

# =============================================================================
# Script : Benchmarks ARKEA
# =============================================================================
# Date : 2025-12-02
# Description : Benchmarks complets pour HCD, Kafka, Spark
# Usage : ./tests/performance/benchmark.sh [--component hcd|kafka|spark|all]
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Charger la configuration
if [ -f "$ARKEA_HOME/.poc-config.sh" ]; then
    source "$ARKEA_HOME/.poc-config.sh"
fi

# Variables
COMPONENT="${1:-all}"
BENCHMARK_DIR="$ARKEA_HOME/tests/performance/results"
BENCHMARK_REPORT="$BENCHMARK_DIR/benchmark_$(date +%Y%m%d_%H%M%S).txt"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Créer le répertoire de résultats
mkdir -p "$BENCHMARK_DIR"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Benchmarks ARKEA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Date : $(date '+%Y-%m-%d %H:%M:%S')"
echo "Composant : $COMPONENT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Fonction pour exécuter un benchmark
run_benchmark() {
    local component="$1"
    local test_file="$SCRIPT_DIR/test_${component}_performance.sh"

    if [ -f "$test_file" ]; then
        echo -e "${BLUE}▶${NC} Benchmark $component"
        echo ""

        if bash "$test_file" >> "$BENCHMARK_REPORT" 2>&1; then
            echo -e "${GREEN}✅ Benchmark $component terminé${NC}"
        else
            echo -e "${YELLOW}⚠️  Benchmark $component terminé avec warnings${NC}"
        fi
        echo ""
    else
        echo -e "${YELLOW}⚠️  Fichier de benchmark non trouvé : $test_file${NC}"
    fi
}

# Exécuter les benchmarks selon le composant
case "$COMPONENT" in
    hcd)
        run_benchmark "hcd"
        ;;
    kafka)
        run_benchmark "kafka"
        ;;
    spark)
        run_benchmark "spark"
        ;;
    all)
        run_benchmark "hcd"
        run_benchmark "kafka"
        run_benchmark "spark"
        ;;
    *)
        echo "Usage: $0 [--component hcd|kafka|spark|all]"
        exit 1
        ;;
esac

# Résumé
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Résumé des Benchmarks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Rapport disponible : $BENCHMARK_REPORT"
echo ""

if [ -f "$BENCHMARK_REPORT" ]; then
    echo "📄 Aperçu du rapport :"
    head -20 "$BENCHMARK_REPORT"
fi

echo ""
echo -e "${GREEN}✅ Benchmarks terminés${NC}"
