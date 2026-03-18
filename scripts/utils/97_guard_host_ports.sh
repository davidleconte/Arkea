#!/usr/bin/env bash
set -euo pipefail
# =============================================================================
# Script : Guard host-side port leaks in active docs/tests
# =============================================================================
# Fails if localhost:9042 or localhost:9092 appears in ACTIVE docs/test docs
# outside valid internal-container contexts.
# =============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "🔍 Scanning ACTIVE docs/test docs for host-side legacy ports (9042/9092)..."

ACTIVE_FILES=(
  "README.md"
  "AGENTS.md"
  "docs/README.md"
  "docs/ARCHITECTURE.md"
  "docs/DEPLOYMENT.md"
  "docs/TROUBLESHOOTING.md"
  "docs/CONFIGURATION_ENVIRONNEMENT.md"
  "docs/GUIDE_DEPENDENCIES.md"
  "docs/API.md"
  "tests/README.md"
)

CANDIDATES="$(
  rg -n "localhost:(9042|9092)" "${ACTIVE_FILES[@]}" || true
)"

# Allow valid internal-container contexts only
LEAKS="$(
  printf '%s\n' "$CANDIDATES" | grep -vE "podman exec|docker exec|container internal|interne|mappé depuis|->" || true
)"

if [ -n "${LEAKS}" ]; then
  echo "❌ Host-side legacy port references detected in ACTIVE docs:"
  echo "$LEAKS"
  echo ""
  echo "Expected host-side ports: localhost:9102 / localhost:9192"
  echo "Allowed exception: internal container commands (podman exec ... localhost:9042/9092)"
  exit 1
fi

echo "✅ No host-side legacy port leaks found in ACTIVE docs/test docs."
