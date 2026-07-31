#!/usr/bin/env bash
# Install allowlisted tools that use first-party installers.

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

    # Fast-moving agent CLIs whose first-party installers self-update same-day. Add nothing here without a one-line reason.
    install_standalone_tool claude "https://claude.ai/install.sh"
    install_standalone_tool codex "https://chatgpt.com/codex/install.sh"
    install_standalone_tool amp "https://ampcode.com/install.sh"
    # Herdr publishes a POSIX installer and manages its own ~/.local/bin binary.
    install_standalone_tool herdr "https://herdr.dev/install.sh" sh
}
