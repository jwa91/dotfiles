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
export DEV_DIR="$HOME/developer"

# Workspace roots
export WORKSPACES_DIR="$DEV_DIR/workspaces"
export SCHEMAS_DIR="$DEV_DIR/schemas"
export PREFERENCES_DIR="$DEV_DIR/preferences"

# ----------------------------------------
# XDG Base Directories
# ----------------------------------------
# Let XDG_CONFIG_HOME default to ~/.config (standard location)
# Apps we control get explicit paths below instead of polluting dotfiles
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# ----------------------------------------
# Default tools
# ----------------------------------------
export EDITOR="${EDITOR:-micro}"
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship.toml"

# ----------------------------------------
# Machine-specific paths
# ----------------------------------------
export VAULT_PATH="$HOME/Library/Mobile Documents/com~apple~CloudDocs/notes"

# ----------------------------------------
# 1Password SSH agent
# Routes ssh-add / ssh's identity lookups through 1Password so private keys
# never live unencrypted on disk. Requires 1Password.app running with the
# SSH agent enabled in Settings → Developer.
# ----------------------------------------
if [[ -S "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" ]]; then
    export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
fi

# ----------------------------------------
# PATH modifications
# Using Zsh 'path' array for cleaner management and duplicate prevention
# ----------------------------------------
typeset -U -x path
path=(
    "$HOME/.local/bin" 
    /opt/homebrew/bin
    /opt/homebrew/sbin
    /usr/local/bin
    $path
)
