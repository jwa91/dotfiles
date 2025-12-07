#!/usr/bin/env bash
# ----------------------------------------
# Git Configuration Setup
# ----------------------------------------
# Creates symlink: ~/.gitconfig -> ~/dotfiles/git/config
#
# Usage: ./setup.sh [--dry-run]
# ----------------------------------------

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Parse arguments
DRY_RUN=false
[[ "$1" == "--dry-run" ]] && DRY_RUN=true && echo -e "${YELLOW}🔍 DRY RUN MODE${NC}\n"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITCONFIG_SOURCE="$SCRIPT_DIR/config"
GITCONFIG_TARGET="$HOME/.gitconfig"

# ----------------------------------------
# Symlink ~/.gitconfig
# ----------------------------------------
if [[ -L "$GITCONFIG_TARGET" ]]; then
    current=$(readlink "$GITCONFIG_TARGET")
    if [[ "$current" == "$GITCONFIG_SOURCE" ]]; then
        echo -e "${GREEN}✓${NC} ~/.gitconfig already linked correctly"
    else
        echo -e "${YELLOW}→${NC} Updating symlink (was: $current)"
        $DRY_RUN || ln -sf "$GITCONFIG_SOURCE" "$GITCONFIG_TARGET"
    fi
elif [[ -e "$GITCONFIG_TARGET" ]]; then
    echo -e "${RED}!${NC} ~/.gitconfig exists but is not a symlink"
    echo "  Backup with: mv ~/.gitconfig ~/.gitconfig.backup"
    exit 1
else
    echo -e "${YELLOW}→${NC} Creating symlink ~/.gitconfig -> $GITCONFIG_SOURCE"
    $DRY_RUN || ln -sf "$GITCONFIG_SOURCE" "$GITCONFIG_TARGET"
fi

# ----------------------------------------
# Verify
# ----------------------------------------
if ! $DRY_RUN; then
    echo -e "\n${GREEN}✓ Git configured${NC}"
    echo "  Verify with: git config --global --list"
fi

