#!/usr/bin/env bash

ensure_git_available() {
    if command -v git >/dev/null 2>&1; then
        log_skip "Git"
        return
    fi

    log_error "Git is missing."
    log_warn "Install Apple Command Line Tools with: xcode-select --install"
    log_warn "Or put your source-built Git on PATH before running bootstrap."
    exit 1
}

ensure_tooling_prerequisites() {
    log_section "Tooling Prerequisites"

    ensure_git_available

    if command -v brew >/dev/null 2>&1; then
        log_skip "Homebrew"
    else
        if $SKIP_BREW; then
            log_error "Homebrew is missing and --no-brew was set."
            exit 1
        fi

        log_action "Install Homebrew"
        run_cmd /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        if ! $DRY_RUN; then
            if [[ -x /opt/homebrew/bin/brew ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -x /usr/local/bin/brew ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        fi
    fi

}

install_brew_bundle() {
    log_section "Homebrew Bundle"

    if $SKIP_BREW; then
        log_skip "brew bundle step (--no-brew)"
        return
    fi

    log_action "Run brew bundle --file=$BREWFILE"
    run_cmd brew bundle --file="$BREWFILE"
}

install_standalone_tools() {
    log_section "Standalone Tools (non-Homebrew)"

    if $SKIP_BREW; then
        log_skip "standalone tools step (--no-brew)"
        return
    fi

    if command -v amp >/dev/null 2>&1; then
        log_skip "amp (already installed)"
        return
    fi

    local amp_url="https://ampcode.com/install.sh"
    log_action "Install amp via $amp_url"
    if ! $DRY_RUN; then
        if curl -fsSL --head "$amp_url" >/dev/null 2>&1; then
            curl -fsSL "$amp_url" | bash
        else
            log_warn "amp install script unreachable at $amp_url; install manually: https://ampcode.com"
        fi
    fi
}
