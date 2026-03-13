#!/bin/bash
# ARKEA POC Onboarding Script
# Run this script to set up a complete development environment
# Usage: ./scripts/setup/00_onboarding.sh [--skip-deps]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "========================================"
echo "  ARKEA POC - Development Onboarding"
echo "========================================"
echo ""

# Check OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Linux"
    else
        echo "Unknown"
    fi
}

OS=$(detect_os)
log_info "Detected OS: $OS"

# Step 1: Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    local missing=()

    # Required tools
    for tool in git make python3; do
        if ! command -v "$tool" &> /dev/null; then
            missing+=("$tool")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing[*]}"
        log_info "Please install them before continuing."
        exit 1
    fi

    log_success "All prerequisites satisfied."
}

# Step 2: Install Python dependencies
install_python_deps() {
    log_info "Setting up Python environment..."

    cd "$PROJECT_ROOT"

    # Create virtual environment if not exists
    if [[ ! -d ".venv" ]]; then
        python3 -m venv .venv
        log_success "Created virtual environment."
    fi

    # Activate and install
    source .venv/bin/activate

    if [[ -f "requirements.txt" ]]; then
        pip install --upgrade pip
        pip install -r requirements.txt
        log_success "Python dependencies installed."
    else
        log_warning "No requirements.txt found, skipping."
    fi
}

# Step 3: Install pre-commit hooks
install_hooks() {
    log_info "Installing pre-commit hooks..."

    if command -v pre-commit &> /dev/null; then
        pre-commit install
        log_success "Pre-commit hooks installed."
    else
        log_warning "pre-commit not found, skipping hooks."
    fi
}

# Step 4: Configure environment
configure_env() {
    log_info "Configuring environment..."

    if [[ -f ".env.example" ]] && [[ ! -f ".env" ]]; then
        cp .env.example .env
        log_success "Created .env from .env.example."
    else
        log_info ".env already exists or no .env.example found."
    fi
}

# Step 5: Verify setup
verify_setup() {
    log_info "Verifying setup..."

    cd "$PROJECT_ROOT"

    # Run quick verification
    if make status 2>/dev/null; then
        log_success "Environment verification passed."
    else
        log_warning "Some services may not be running. Use 'make start' to start them."
    fi
}

# Main execution
main() {
    local skip_deps=false

    if [[ "${1:-}" == "--skip-deps" ]]; then
        skip_deps=true
    fi

    check_prerequisites

    if [[ "$skip_deps" == false ]]; then
        install_python_deps
    fi

    install_hooks
    configure_env
    verify_setup

    echo ""
    echo "========================================"
    log_success "Onboarding complete! 🎉"
    echo "========================================"
    echo ""
    echo "Next steps:"
    echo "  1. Review .env and configure your settings"
    echo "  2. Run 'make start' to start services"
    echo "  3. Run 'make test' to verify everything works"
    echo "  4. Open VS Code and install recommended extensions"
    echo ""
}

main "$@"
