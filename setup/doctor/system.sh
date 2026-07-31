#!/usr/bin/env bash

doctor_system() {
    local failed=0

    check_required_commands || failed=1
    check_optional_commands
    check_directories || failed=1
    check_ssh_agent

    return "$failed"
}

check_required_commands() {
    log_section "Required Commands"

    local failed=0
    local command_name
    local commands=(
        brew git starship fzf tmux micro zoxide atuin duti hunk
        eza just prek gitleaks op pass-cli jq rg uv mise cheat tldr tofu tflint
    )

    for command_name in "${commands[@]}"; do
        if command -v "$command_name" >/dev/null 2>&1; then
            log_skip "$command_name"
        else
            log_error "$command_name not found"
            failed=1
        fi
    done

    return "$failed"
}

check_optional_commands() {
    log_section "Optional Commands"

    local command_name
    local commands=(amp cursor tailscale)

    for command_name in "${commands[@]}"; do
        if command -v "$command_name" >/dev/null 2>&1; then
            log_skip "$command_name"
        else
            log_warn "$command_name not found"
        fi
    done
}

check_directories() {
    log_section "Directories"

    local failed=0
    local directory
    local directories=(
        "$DOTFILES_DIR"
        "$CONFIG_DIR"
        "$GIT_DIR"
        "$ZSH_DIR"
        "$HOME/developer"
        "$HOME/.zsh_plugins"
        "$HOME/.zfunc"
        "$HOME/.local/bin"
    )

    for directory in "${directories[@]}"; do
        if [[ -d "$directory" ]]; then
            log_skip "$directory"
        else
            log_error "$directory missing"
            failed=1
        fi
    done

    return "$failed"
}

check_ssh_agent() {
    log_section "SSH Agent"

    # 1Password wins when both supported agent sockets exist.
    local op_socket="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    local proton_socket="${PROTON_PASS_SSH_AUTH_SOCK:-$HOME/.ssh/proton-pass-agent.sock}"
    local vault="${PROTON_PASS_SSH_VAULT:-Work}"

    if [[ -S "$op_socket" ]]; then
        log_skip "1Password agent: $op_socket"
    elif [[ -S "$proton_socket" ]]; then
        log_skip "Proton Pass agent: $proton_socket (vault: $vault)"
    else
        log_warn "No SSH agent socket found; enable the 1Password SSH agent (Settings -> Developer) or run: ppagent start"
    fi
}
