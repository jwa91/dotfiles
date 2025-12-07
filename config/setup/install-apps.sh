#!/usr/bin/env bash
# ----------------------------------------
# File: install-apps.sh
# Description: Installs GUI applications and extra tools via Homebrew.
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
log_action() { 
    if $DRY_RUN; then echo -e "${YELLOW}○ WOULD:${NC} $1"; else echo -e "${YELLOW}→ ACTION:${NC} $1"; fi 
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="$SCRIPT_DIR/Brewfile-apps"

echo -e "\n${BLUE}━━━ Installing Applications ━━━${NC}"

if [[ -f "$BREWFILE" ]]; then
    if $DRY_RUN; then
        echo -e "${YELLOW}○ WOULD:${NC} Install applications from Brewfile-apps:"
        grep -E "^(brew|cask)" "$BREWFILE" | sed 's/^/    /'
    else
        log_action "Running brew bundle..."
        brew bundle --file="$BREWFILE"
    fi
else
    echo -e "${RED}Error: Brewfile-apps not found at $BREWFILE${NC}"
    exit 1
fi

echo -e "\n${GREEN}✓ Application installation complete!${NC}"




