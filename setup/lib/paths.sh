#!/usr/bin/env bash

ZSH_DIR="$DOTFILES_DIR/zsh"
CONFIG_DIR="$DOTFILES_DIR/config"
GIT_DIR="$DOTFILES_DIR/git"
BREWFILE="$DOTFILES_DIR/Brewfile"
# shellcheck disable=SC2034 # Consumed by setup/init/manual.sh after init sources modules.
MANUAL_INSTALLS_FILE="$DOTFILES_DIR/setup/manual-installs.txt"
DOTFILES_LOCAL_CONFIG_DIR="${DOTFILES_LOCAL_CONFIG_DIR:-$HOME/.config/dotfiles-local}"

# Mirrors zsh/env.zsh so setup and doctor agree with the shell about where zsh
# state lives, even when run from an environment that never sourced env.zsh.
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
ZSH_PLUGINS_DIR="${ZSH_PLUGINS_DIR:-$XDG_DATA_HOME/zsh/plugins}"
ZSH_STATE_DIR="${ZSH_STATE_DIR:-$XDG_STATE_HOME/zsh}"
# shellcheck disable=SC2034 # Consumed by setup/init/zsh.sh.
ZSH_CACHE_DIR="${ZSH_CACHE_DIR:-$XDG_CACHE_HOME/zsh}"

setup_path() {
    PATH="$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"
    export PATH
}

preflight() {
    log_section "Preflight"

    if [[ "$(uname -s)" != "Darwin" ]]; then
        log_error "This setup currently supports macOS only."
        exit 1
    fi

    local required_paths=(
        "$BREWFILE"
        "$CONFIG_DIR"
        "$GIT_DIR/config"
        "$GIT_DIR/config.local.example"
        "$GIT_DIR/commit_template.txt"
        "$GIT_DIR/ignore"
        "$DOTFILES_DIR/lib/dotfiles/shim-policy.bash"
        "$DOTFILES_DIR/libexec/dotfiles/toolchain-shim"
        "$DOTFILES_DIR/libexec/dotfiles/starship-js-package-manager"
        "$DOTFILES_DIR/libexec/dotfiles/starship-uv-python"
        "$ZSH_DIR/env.zsh"
        "$ZSH_DIR/.zshrc"
        "$ZSH_DIR/.zshenv"
        "$ZSH_DIR/.zprofile"
        "$ZSH_DIR/path.zsh"
    )

    local required
    for required in "${required_paths[@]}"; do
        if [[ ! -e "$required" ]]; then
            log_error "Required path missing: $required"
            exit 1
        fi
    done

    log_skip "Repository root: $DOTFILES_DIR"
    log_skip "Brewfile: $BREWFILE"
}
