#!/usr/bin/env bash
# ----------------------------------------
# File: install-tools.sh
# Description: Part 2 - Installs developer tools and languages.
#              Uses Homebrew to manage pnpm, uv, bun, etc.
# ----------------------------------------

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo -e "${BLUE}🔍 DRY RUN MODE - No changes will be made${NC}\n"
fi

# Helpers
log_skip() { echo -e "${GREEN}✓ SKIP:${NC} $1"; }
log_action() { 
    if $DRY_RUN; then echo -e "${YELLOW}○ WOULD:${NC} $1"; else echo -e "${YELLOW}→ ACTION:${NC} $1"; fi 
}
log_section() { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }
run_cmd() { if ! $DRY_RUN; then "$@"; fi; }

# ========================================
# 1. Homebrew Bundle
# ========================================
log_section "Installing Tools via Homebrew"

# Ensure Homebrew exists
if ! command -v brew &> /dev/null; then
    echo -e "${RED}Error: Homebrew not found.${NC}"
    echo "Please run install-zsh.sh first or install Homebrew manually."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="$SCRIPT_DIR/Brewfile"

if [[ -f "$BREWFILE" ]]; then
    if $DRY_RUN; then
        echo -e "${YELLOW}○ WOULD:${NC} Install packages from Brewfile:"
        grep -E "^(brew|cask|tap)" "$BREWFILE" | sed 's/^/    /'
    else
        log_action "Running brew bundle..."
        # brew bundle handles dependency checking automatically
        brew bundle --file="$BREWFILE"
    fi
else
    echo -e "${RED}Error: Brewfile not found at $BREWFILE${NC}"
    exit 1
fi

# ========================================
# 2. Python Template & Functions
# ========================================
log_section "Python Tools"

PYTHON_TEMPLATE_DIR="$HOME/Developer/templates/python"

if [[ -d "$PYTHON_TEMPLATE_DIR" ]]; then
    log_skip "Python template already exists at $PYTHON_TEMPLATE_DIR"
else
    log_action "Cloning Python template (includes python-functions.sh)"
    run_cmd mkdir -p "$(dirname "$PYTHON_TEMPLATE_DIR")"
    run_cmd git clone https://github.com/jwa91/python-template.git "$PYTHON_TEMPLATE_DIR"
fi

# ========================================
# 3. Post-Install Checks
# ========================================
log_section "Verifying Installations"

check_tool() {
    local tool="$1"
    if command -v "$tool" &> /dev/null; then
        echo -e "${GREEN}✓ $tool${NC} installed: $(eval "$tool --version" 2>/dev/null || echo 'present')"
    else
        echo -e "${RED}✗ $tool${NC} is missing"
    fi
}

# Check the main tools we expect
if ! $DRY_RUN; then
    check_tool "bun"
    check_tool "pnpm"
    check_tool "uv"
    check_tool "starship"
    check_tool "fzf"
fi

echo -e "\n${GREEN}✓ Developer tools installation complete!${NC}"
