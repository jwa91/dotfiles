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
# SSH agent — transition state: 1Password is the current truth, Proton Pass
# is the delayed migration target. Both checks are socket-gated, so machines
# running only one agent are unaffected; when both sockets exist, 1Password
# wins because its check runs last.
# pass-cli's daemon defaults to ~/.ssh/proton-pass-agent.sock.
# ----------------------------------------
export PROTON_PASS_SSH_VAULT="${PROTON_PASS_SSH_VAULT:-Work}"
export PROTON_PASS_SSH_AUTH_SOCK="${PROTON_PASS_SSH_AUTH_SOCK:-$HOME/.ssh/proton-pass-agent.sock}"

if [[ -S "$PROTON_PASS_SSH_AUTH_SOCK" ]]; then
    export SSH_AUTH_SOCK="$PROTON_PASS_SSH_AUTH_SOCK"
fi

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
