#!/bin/bash
set -euo pipefail
# ARKEA POC Onboarding Script
# Run this script to set up a complete development environment
# Usage: ./scripts/setup/00_onboarding.sh [--skip-deps] [--dry-run]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_dry_run() { echo -e "${CYAN}[DRY-RUN]${NC} $1"; }

# Global flags
DRY_RUN=false
SKIP_DEPS=false

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

# Step 1: Check prerequisites
check_prerequisites() {
    if [[ "$DRY_RUN" == true ]]; then
        log_dry_run "Would check prerequisites: git, make, python3"
        return 0
    fi

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
    if [[ "$DRY_RUN" == true ]]; then
        log_dry_run "Would create .venv and install requirements.txt"
        return 0
    fi

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
    if [[ "$DRY_RUN" == true ]]; then
        log_dry_run "Would run: pre-commit install"
        return 0
    fi

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
    if [[ "$DRY_RUN" == true ]]; then
        if [[ -f ".env.example" ]]; then
            log_dry_run "Would copy .env.example -> .env"
        else
            log_dry_run "No .env.example found, would skip"
        fi
        return 0
    fi

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
    if [[ "$DRY_RUN" == true ]]; then
        log_dry_run "Would run: make status"
        return 0
    fi

    log_info "Verifying setup..."

    cd "$PROJECT_ROOT"

    # Run quick verification
    if make status 2>/dev/null; then
        log_success "Environment verification passed."
    else
        log_warning "Some services may not be running. Use 'make start' to start them."
    fi
}

# Show help
show_help() {
    cat << EOF
ARKEA POC Onboarding Script

Usage: $0 [OPTIONS]

Options:
    --skip-deps    Skip Python dependency installation
    --dry-run      Preview actions without executing
    --help         Show this help message

Examples:
    $0                    # Full setup
    $0 --skip-deps        # Skip pip install
    $0 --dry-run          # Preview changes
    $0 --dry-run --skip-deps  # Preview without deps

EOF
    exit 0
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --skip-deps)
                SKIP_DEPS=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help|-h)
                show_help
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                ;;
        esac
    done
}

# Main execution
main() {
    parse_args "$@"

    local OS
    OS=$(detect_os)

    if [[ "$DRY_RUN" == true ]]; then
        echo "========================================"
        echo "  ARKEA POC - DRY RUN MODE"
        echo "========================================"
        log_info "Detected OS: $OS"
        log_info "No changes will be made"
        echo ""
    else
        echo "========================================"
        echo "  ARKEA POC - Development Onboarding"
        echo "========================================"
        echo ""
        log_info "Detected OS: $OS"
    fi

    check_prerequisites

    if [[ "$SKIP_DEPS" == false ]]; then
        install_python_deps
    elif [[ "$DRY_RUN" == true ]]; then
        log_dry_run "Skipping Python deps (--skip-deps)"
    fi

    install_hooks
    configure_env
    verify_setup

    echo ""
    echo "========================================"
    if [[ "$DRY_RUN" == true ]]; then
        log_success "Dry run complete! Run without --dry-run to apply changes."
    else
        log_success "Onboarding complete! 🎉"
    fi
    echo "========================================"
    echo ""

    if [[ "$DRY_RUN" == false ]]; then
        echo "Next steps:"
        echo "  1. Review .env and configure your settings"
        echo "  2. Run 'make start' to start services"
        echo "  3. Run 'make test' to verify everything works"
        echo "  4. Open VS Code and install recommended extensions"
        echo ""
    fi
}

main "$@"
