# Shared Zsh environment.

export DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
export CONFIG_DIR="${CONFIG_DIR:-$DOTFILES_DIR/config}"
export GITCONFIG_DIR="${GITCONFIG_DIR:-$DOTFILES_DIR/git}"
export ZSH_DIR="${ZSH_DIR:-$DOTFILES_DIR/zsh}"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Zsh state, split by XDG category: plugins are replaceable data, history is
# state worth keeping, the completion dump is a rebuildable cache.
export ZSH_PLUGINS_DIR="${ZSH_PLUGINS_DIR:-$XDG_DATA_HOME/zsh/plugins}"
export ZSH_STATE_DIR="${ZSH_STATE_DIR:-$XDG_STATE_HOME/zsh}"
export ZSH_CACHE_DIR="${ZSH_CACHE_DIR:-$XDG_CACHE_HOME/zsh}"

export DEV_DIR="${DEV_DIR:-$HOME/developer}"
export VAULT_PATH="${VAULT_PATH:-$HOME/Library/Mobile Documents/com~apple~CloudDocs/notes}"

export EDITOR="${EDITOR:-micro}"
export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$XDG_CONFIG_HOME/starship.toml}"
export EZA_CONFIG_DIR="${EZA_CONFIG_DIR:-$XDG_CONFIG_HOME/eza}"
export EZA_ICON_SPACING="${EZA_ICON_SPACING:-2}"
export EZA_ICONS_AUTO="${EZA_ICONS_AUTO:-1}"

# uv owns Python runtimes and environments. Require uv-managed interpreters so
# `uv run` does not silently fall back to system or framework Python.
export UV_MANAGED_PYTHON="${UV_MANAGED_PYTHON:-1}"

# Brew casks are bootstrap installers here; apps with their own updater should
# not be chased by routine `brew upgrade`.
export HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS="${HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS:-1}"

# 1Password is the current secrets/SSH-agent owner. Proton Pass remains
# optional while it is being evaluated.
export PROTON_PASS_SSH_VAULT="${PROTON_PASS_SSH_VAULT:-Work}"
export PROTON_PASS_SSH_AUTH_SOCK="${PROTON_PASS_SSH_AUTH_SOCK:-$HOME/.ssh/proton-pass-agent.sock}"
