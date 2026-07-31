#!/usr/bin/env bash

doctor_homebrew() {
    local failed=0

    check_homebrew_policy || failed=1
    check_brew_bundle

    return "$failed"
}

check_brew_bundle() {
    log_section "Brew Bundle"

    # Presence-only: self-updating casks run ahead of brew's recorded versions by design, so version drift is not drift.
    if HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_BUNDLE_NO_UPGRADE=1 brew bundle check --file="$BREWFILE" >/dev/null 2>&1; then
        log_skip "Brewfile satisfied"
    else
        log_warn "Brewfile drift; inspect with: HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_BUNDLE_NO_UPGRADE=1 brew bundle check --verbose --file=$BREWFILE"
    fi
}

check_homebrew_policy() {
    log_section "Homebrew Policy"

    local brew_major brew_version failed=0
    brew_version="$(brew --version 2>/dev/null | awk 'NR == 1 { print $2 }')"
    brew_major="${brew_version%%.*}"
    if [[ "$brew_major" =~ ^[0-9]+$ ]] && ((brew_major >= 6)); then
        log_skip "Homebrew $brew_version"
    else
        log_error "Homebrew 6+ required; found ${brew_version:-unknown}"
        failed=1
    fi
    if brew developer state 2>&1 | grep -q "Developer mode is enabled"; then
        log_error "Homebrew tracks main; run: brew developer off"
        failed=1
    else
        log_skip "Homebrew stable release channel"
    fi
    if [[ "${HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS:-}" == "1" ]]; then
        log_skip "self-updating casks excluded from routine brew upgrades"
    else
        log_error "HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS must be 1"
        failed=1
    fi
    if [[ -n "${HOMEBREW_UPGRADE_GREEDY+x}${HOMEBREW_UPGRADE_AUTO_UPDATES_CASKS+x}" ]]; then
        log_error "Homebrew greedy upgrade variables must remain unset"
        failed=1
    else
        log_skip "Homebrew greedy upgrade variables unset"
    fi
    return "$failed"
}
