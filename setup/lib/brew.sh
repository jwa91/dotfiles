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

install_standalone_tool() {
    local name="$1"
    local url="$2"

    if command -v "$name" >/dev/null 2>&1; then
        log_skip "$name (already installed)"
        return
    fi

    log_action "Install $name via $url"
    if ! $DRY_RUN; then
        if curl -fsSL --head "$url" >/dev/null 2>&1; then
            curl -fsSL "$url" | bash
        else
            log_warn "$name install script unreachable at $url; install manually"
        fi
    fi
}

install_standalone_tools() {
    log_section "Standalone Tools (non-Homebrew)"

    if $SKIP_BREW; then
        log_skip "standalone tools step (--no-brew)"
        return
    fi

    # The closed exception list to "everything installs via the Brewfile":
    # fast-moving agent CLIs whose first-party installers self-update
    # same-day. Add nothing here without a one-line reason.
    install_standalone_tool claude "https://claude.ai/install.sh"
    install_standalone_tool codex "https://chatgpt.com/codex/install.sh"
    install_standalone_tool amp "https://ampcode.com/install.sh"
}
