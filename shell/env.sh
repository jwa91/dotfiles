# shellcheck shell=sh
# Shared login environment for shells.
#
# Keep this file POSIX-sh compatible. Shell-specific behavior belongs in
# zsh/, bash/, or fish/ so switching shells does not change system ownership.

export DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
export CONFIG_DIR="${CONFIG_DIR:-$DOTFILES_DIR/config}"
export GITCONFIG_DIR="${GITCONFIG_DIR:-$DOTFILES_DIR/git}"
export ZSH_DIR="${ZSH_DIR:-$DOTFILES_DIR/zsh}"
export ZSH_PLUGINS_DIR="${ZSH_PLUGINS_DIR:-$HOME/.zsh_plugins}"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

export DEV_DIR="${DEV_DIR:-$HOME/developer}"
export VAULT_PATH="${VAULT_PATH:-$HOME/Library/Mobile Documents/com~apple~CloudDocs/notes}"

export EDITOR="${EDITOR:-micro}"
export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$XDG_CONFIG_HOME/starship.toml}"

# Brew casks are bootstrap installers here; apps with their own updater should
# not be chased by routine `brew upgrade`.
export HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS="${HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS:-1}"

# 1Password is the current secrets/SSH-agent owner. Proton Pass remains
# optional while it is being evaluated.
export PROTON_PASS_SSH_VAULT="${PROTON_PASS_SSH_VAULT:-Work}"
export PROTON_PASS_SSH_AUTH_SOCK="${PROTON_PASS_SSH_AUTH_SOCK:-$HOME/.ssh/proton-pass-agent.sock}"
