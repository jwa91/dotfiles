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

    local brew_major brew_version
    brew_version="$(brew --version | awk 'NR == 1 { print $2 }')"
    brew_major="${brew_version%%.*}"
    if [[ "$brew_major" =~ ^[0-9]+$ ]] && ((brew_major < 6)); then
        log_action "Update Homebrew to 6+"
        run_cmd brew update
    else
        log_skip "Homebrew $brew_version"
    fi

    if brew developer state 2>&1 | grep -q "Developer mode is enabled"; then
        log_action "Return Homebrew to the stable release channel"
        run_cmd brew developer off
        run_cmd brew update
    else
        log_skip "Homebrew stable release channel"
    fi

    log_action "Run brew bundle with HOMEBREW_BUNDLE_NO_UPGRADE=1 --file=$BREWFILE"
    run_cmd env HOMEBREW_BUNDLE_NO_UPGRADE=1 brew bundle --file="$BREWFILE"
}

install_mise_toolchains() {
    log_section "Mise Toolchains"
    local failed=0

    if $SKIP_BREW; then
        log_skip "mise toolchain step (--no-brew)"
        return
    fi

    if ! command -v mise >/dev/null 2>&1; then
        if $DRY_RUN; then
            log_warn "mise is missing now, but brew bundle would install it before toolchains"
        else
            log_error "mise is missing; run the brew target first"
            failed=1
        fi
    fi

    if [[ ! -f "$HOME/.config/mise/config.toml" ]]; then
        if $DRY_RUN; then
            log_warn "$HOME/.config/mise/config.toml missing now, but links would create it before toolchains"
        else
            log_error "$HOME/.config/mise/config.toml missing; run the links target first"
            failed=1
        fi
    fi

    if [[ "$failed" -ne 0 ]]; then
        exit 1
    fi

    log_action "Trust mise config"
    run_cmd mise trust "$HOME/.config/mise/config.toml"

    log_action "Install repo-declared mise toolchains"
    run_cmd mise install
}

install_standalone_tool() {
    local name="$1"
    local url="$2"
    local interpreter="${3:-bash}"

    if command -v "$name" >/dev/null 2>&1; then
        log_skip "$name (already installed)"
        return
    fi

    log_action "Install $name via $url"
    if ! $DRY_RUN; then
        if curl -fsSL --head "$url" >/dev/null 2>&1; then
            curl -fsSL "$url" | "$interpreter"
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

    # Fast-moving agent CLIs whose first-party installers self-update
    # same-day. Add nothing here without a one-line reason.
    install_standalone_tool claude "https://claude.ai/install.sh"
    install_standalone_tool codex "https://chatgpt.com/codex/install.sh"
    install_standalone_tool amp "https://ampcode.com/install.sh"
    # Herdr publishes a POSIX installer and manages its own ~/.local/bin binary.
    install_standalone_tool herdr "https://herdr.dev/install.sh" sh
}
