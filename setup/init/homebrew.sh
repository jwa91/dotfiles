#!/usr/bin/env bash
# Ensure Homebrew and the Brewfile inventory are installed.

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
        log_action "Install Homebrew"
        if $DRY_RUN; then
            log_skip "/bin/bash -c <Homebrew installer>"
        else
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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

    if $DRY_RUN && ! command -v brew >/dev/null 2>&1; then
        log_warn "Homebrew is missing now, but init would install it before running brew bundle"
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
