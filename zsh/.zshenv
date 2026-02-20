# ----------------------------------------
# Core Dotfiles Directories
# ----------------------------------------
export DOTFILES_DIR="$HOME/dotfiles"
export CONFIG_DIR="$DOTFILES_DIR/config"
export GITCONFIG_DIR="$DOTFILES_DIR/git"
export ZSH_DIR="${ZSH_DIR:-$DOTFILES_DIR/zsh}"
export ZSH_PLUGINS_DIR="$HOME/.zsh_plugins"

# ----------------------------------------
# External Directories
# ----------------------------------------
export DEV_DIR="${DEV_DIR:-$HOME/Developer}"

# ----------------------------------------
# XDG Base Directories
# ----------------------------------------
# Let XDG_CONFIG_HOME default to ~/.config (standard location)
# Apps we control get explicit paths below instead of polluting dotfiles
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# ----------------------------------------
# Specific Configurations
# ----------------------------------------
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship.toml"

# ----------------------------------------
# Machine-specific paths
# ----------------------------------------
export VAULT_PATH="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Obsidian"

# ----------------------------------------
# PATH modifications
# Define tool-specific homes/paths BEFORE modifying PATH array
export BUN_INSTALL="$HOME/.bun"
export PNPM_HOME="$HOME/Library/pnpm"

# ----------------------------------------
# PATH modifications
# Using Zsh 'path' array for cleaner management and duplicate prevention
# ----------------------------------------
typeset -U -x path
path=(
    "$HOME/.local/bin" 
    /opt/homebrew/opt/node@24/bin  # Node 24 LTS
    /opt/homebrew/bin
    /opt/homebrew/sbin
    /usr/local/bin
    "$HOME/.npm-global/bin"
    "$BUN_INSTALL/bin"
    "$HOME/.antigravity/antigravity/bin"
    $path
)
if [[ -d "$PNPM_HOME" && "${path[(i)$PNPM_HOME]}" -gt "${#path}" ]]; then
    path=("$PNPM_HOME" $path)
fi
