#!/usr/bin/env bash
# ----------------------------------------
# File: install-zsh.sh
# Description: Part 1 - Sets up Zsh configuration, plugins, and symlinks.
#              Focuses on the shell environment itself.
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
log_error() { echo -e "${RED}✗ ERROR:${NC} $1"; }
log_section() { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }
run_cmd() { if ! $DRY_RUN; then "$@"; fi; }

# ========================================
# 1. Prerequisites (Homebrew & Git)
# ========================================
log_section "Prerequisites"

# Check Homebrew
if command -v brew &> /dev/null; then
    log_skip "Homebrew is installed"
else
    log_action "Install Homebrew"
    run_cmd /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Check Git
if command -v git &> /dev/null; then
    log_skip "Git is installed"
else
    log_action "Install Git"
    run_cmd brew install git
fi

# ========================================
# 2. Core Shell Dependencies
# ========================================
log_section "Shell Dependencies"

# We install these immediately as they are required for the prompt/shell to render correctly
for pkg in starship fzf; do
    if brew list "$pkg" &> /dev/null; then
        log_skip "$pkg"
    else
        log_action "Install $pkg"
        run_cmd brew install "$pkg"
    fi
done

# ========================================
# 3. ZSH Plugins
# ========================================
log_section "ZSH Plugins"

ZSH_PLUGINS_DIR="$HOME/.zsh_plugins"
if [[ ! -d "$ZSH_PLUGINS_DIR" ]]; then
    log_action "Create $ZSH_PLUGINS_DIR"
    run_cmd mkdir -p "$ZSH_PLUGINS_DIR"
fi

plugins="zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search"
plugin_urls=(
    "https://github.com/zsh-users/zsh-autosuggestions"
    "https://github.com/zsh-users/zsh-syntax-highlighting"
    "https://github.com/zsh-users/zsh-history-substring-search"
)

i=0
for plugin in $plugins; do
    plugin_path="$ZSH_PLUGINS_DIR/$plugin"
    url="${plugin_urls[$i]}"
    if [[ -d "$plugin_path" ]]; then
        log_skip "$plugin"
    else
        log_action "Clone $plugin"
        run_cmd git clone --depth 1 "$url" "$plugin_path"
    fi
    ((i++))
done

# ========================================
# 4. Directories
# ========================================
log_section "Directories"

directories=(
    "$HOME/Developer"
    "$HOME/.local/bin"
    "$HOME/.npm-global/bin"
)

for dir in "${directories[@]}"; do
    if [[ -d "$dir" ]]; then
        log_skip "$dir"
    else
        log_action "Create $dir"
        run_cmd mkdir -p "$dir"
    fi
done

# ========================================
# 5. Symlinks
# ========================================
log_section "Symlinks"

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
ZSH_DIR="$DOTFILES_DIR/zsh"

create_symlink() {
    local target="$1"
    local source="$2"
    
    if [[ -L "$target" ]]; then
        current_source=$(readlink "$target")
        if [[ "$current_source" == "$source" ]]; then
            log_skip "$target -> $source"
        else
            log_action "Update symlink $target -> $source"
            run_cmd ln -sf "$source" "$target"
        fi
    elif [[ -e "$target" ]]; then
        if [[ "$target" -ef "$source" ]]; then
            log_skip "$target -> $source (via parent symlink or hardlink)"
        else
            log_error "$target exists but is not a symlink. Backup and remove it manually."
        fi
    else
        log_action "Create symlink $target -> $source"
        run_cmd ln -sf "$source" "$target"
    fi
}

create_symlink "$HOME/.zshrc" "$ZSH_DIR/.zshrc"
create_symlink "$HOME/.zshenv" "$ZSH_DIR/.zshenv"
create_symlink "$HOME/.zprofile" "$ZSH_DIR/.zprofile"

# Application Configs
mkdir -p "$HOME/.config/ghostty"
create_symlink "$HOME/.config/ghostty/config" "$DOTFILES_DIR/config/ghostty/config"

# Starship Config
create_symlink "$HOME/.config/starship.toml" "$DOTFILES_DIR/config/starship.toml"

# ========================================
# 6. Secrets
# ========================================
log_section "Secrets"

SECRETS_FILE="$ZSH_DIR/secrets.zsh"
# Assuming the script is run from zsh/setup/ or we find the file relative to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_EXAMPLE="$SCRIPT_DIR/secrets.example.zsh"

if [[ -f "$SECRETS_FILE" ]]; then
    log_skip "secrets.zsh"
else
    if [[ -f "$SECRETS_EXAMPLE" ]]; then
        log_action "Copy secrets.example.zsh to secrets.zsh"
        run_cmd cp "$SECRETS_EXAMPLE" "$SECRETS_FILE"
    else
        log_action "Create empty secrets.zsh"
        run_cmd touch "$SECRETS_FILE"
    fi
fi

echo -e "\n${GREEN}✓ Zsh configuration complete!${NC}"
echo -e "Next: Run ${YELLOW}./install-tools.sh${NC} to install developer tools."

