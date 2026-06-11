#!/usr/bin/env bash

ZSH_DIR="$DOTFILES_DIR/zsh"
CONFIG_DIR="$DOTFILES_DIR/config"
GIT_DIR="$DOTFILES_DIR/git"
BREWFILE="$DOTFILES_DIR/Brewfile"
# shellcheck disable=SC2034 # Consumed by setup/lib/manual.sh after bootstrap sources modules.
MANUAL_INSTALLS_FILE="$DOTFILES_DIR/setup/manual-installs.txt"
DOTFILES_LOCAL_CONFIG_DIR="${DOTFILES_LOCAL_CONFIG_DIR:-$HOME/.config/dotfiles-local}"

preflight() {
    log_section "Preflight"

    if [[ "$(uname -s)" != "Darwin" ]]; then
        log_error "This bootstrap currently supports macOS only."
        exit 1
    fi

    local required_paths=(
        "$BREWFILE"
        "$CONFIG_DIR"
        "$GIT_DIR/config"
        "$GIT_DIR/config.local.example"
        "$GIT_DIR/commit_template.txt"
        "$GIT_DIR/ignore"
        "$ZSH_DIR/.zshrc"
        "$ZSH_DIR/.zshenv"
        "$ZSH_DIR/.zprofile"
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
