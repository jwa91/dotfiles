# ----------------------------------------
# Core Dotfiles Directories
# ----------------------------------------
export DOTFILES_DIR="$HOME/dotfiles"
export CONFIG_DIR="$DOTFILES_DIR/config"
export GITCONFIG_DIR="$DOTFILES_DIR/git"
export ZSH_DIR="${ZSH_DIR:-$DOTFILES_DIR/zsh}"
export ZSH_PLUGINS_DIR="$HOME/.zsh_plugins"

# ----------------------------------------
# XDG Base Directories
# ----------------------------------------
# Let XDG_CONFIG_HOME default to ~/.config (standard location)
# Apps we control get explicit paths below instead of polluting dotfiles
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# ----------------------------------------
# User Directories
# ----------------------------------------
export DEV_DIR="$HOME/developer"
export VAULT_PATH="$HOME/Library/Mobile Documents/com~apple~CloudDocs/notes"

# ----------------------------------------
# Default tools
# ----------------------------------------
export EDITOR="${EDITOR:-micro}"
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship.toml"

# ----------------------------------------
# Proton Pass SSH agent
# pass-cli's daemon defaults to ~/.ssh/proton-pass-agent.sock.
# ----------------------------------------
export PROTON_PASS_SSH_VAULT="${PROTON_PASS_SSH_VAULT:-Work}"
export PROTON_PASS_SSH_AUTH_SOCK="${PROTON_PASS_SSH_AUTH_SOCK:-$HOME/.ssh/proton-pass-agent.sock}"

if [[ -S "$PROTON_PASS_SSH_AUTH_SOCK" ]]; then
    export SSH_AUTH_SOCK="$PROTON_PASS_SSH_AUTH_SOCK"
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
