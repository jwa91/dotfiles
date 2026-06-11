#!/usr/bin/env bash

doctor() {
    local failed=0

    log_section "Doctor"

    preflight
    check_required_commands || failed=1
    check_optional_commands
    check_directories || failed=1
    check_zsh_plugins || failed=1
    check_runtime_seeds || failed=1
    check_runtime_files
    check_managed_sources || failed=1
    check_managed_links || failed=1
    check_proton_pass_agent
    check_starship_config

    if [[ $failed -ne 0 ]]; then
        log_error "Doctor found issues. Run ./setup/bootstrap.sh to repair managed state."
        exit 1
    fi

    log_skip "Doctor checks passed"
}

check_proton_pass_agent() {
    log_section "Proton Pass SSH Agent"

    local socket_path="${PROTON_PASS_SSH_AUTH_SOCK:-$HOME/.ssh/proton-pass-agent.sock}"
    local vault="${PROTON_PASS_SSH_VAULT:-Work}"

    if [[ -S "$socket_path" ]]; then
        log_skip "$socket_path"
    else
        log_warn "$socket_path not found; run: pass-cli ssh-agent daemon start --vault-name \"$vault\" --create-new-identities \"$vault\" --socket-path \"$socket_path\""
    fi

    if [[ "${SSH_AUTH_SOCK:-}" == "$socket_path" ]]; then
        log_skip "SSH_AUTH_SOCK -> $socket_path"
    else
        log_warn "Current SSH_AUTH_SOCK is '${SSH_AUTH_SOCK:-unset}'; new shells will use $socket_path when it exists"
    fi

    log_skip "Proton SSH vault: $vault"
}

check_required_commands() {
    log_section "Required Commands"

    local failed=0
    local command_name
    local commands=(
        brew git starship fzf tmux micro zoxide atuin
        pass-cli jq rg
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
    local commands=(amp cursor docker tailscale)

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

check_zsh_plugins() {
    log_section "Zsh Plugins"

    local failed=0
    local plugin plugin_path
    local plugin_root="${ZSH_PLUGINS_DIR:-$HOME/.zsh_plugins}"
    local plugins=(zsh-autosuggestions zsh-syntax-highlighting)

    for plugin in "${plugins[@]}"; do
        plugin_path="$plugin_root/$plugin"
        if [[ -d "$plugin_path" ]]; then
            log_skip "$plugin_path"
        else
            log_error "$plugin_path missing"
            failed=1
        fi
    done

    return "$failed"
}

check_runtime_seeds() {
    log_section "Runtime Seeds"

    local failed=0
    local spec _runtime_file example_file _condition
    for spec in "${RUNTIME_FILES[@]}"; do
        split_spec "$spec" _runtime_file example_file _condition
        if [[ -f "$example_file" ]]; then
            log_skip "$example_file"
        elif $ALLOW_EMPTY_RUNTIME; then
            log_warn "$example_file missing, allowed by --allow-empty-runtime"
        else
            log_error "Runtime seed missing: $example_file"
            failed=1
        fi
    done

    return "$failed"
}

check_runtime_files() {
    log_section "Runtime Files"

    local spec runtime_file example_file condition
    for spec in "${RUNTIME_FILES[@]}"; do
        split_spec "$spec" runtime_file example_file condition
        if ! should_manage_condition "$condition"; then
            log_skip "$runtime_file ($condition not detected)"
        elif [[ -f "$runtime_file" ]]; then
            log_skip "$runtime_file"
        elif [[ -f "$example_file" ]]; then
            log_warn "$runtime_file missing; bootstrap can seed it from $example_file"
        else
            log_warn "$runtime_file missing and seed is unavailable"
        fi
    done
}

check_managed_sources() {
    log_section "Managed Sources"

    local failed=0
    local spec target source _condition
    for spec in "${MANAGED_LINKS[@]}"; do
        split_spec "$spec" target source _condition
        if [[ -e "$source" ]]; then
            log_skip "$source"
        elif runtime_source_planned "$source"; then
            log_skip "$source (runtime seed available)"
        else
            log_error "Managed source missing for $target: $source"
            failed=1
        fi
    done

    return "$failed"
}

check_managed_links() {
    log_section "Managed Links"

    local failed=0
    local spec target source condition current_target

    for spec in "${MANAGED_LINKS[@]}"; do
        split_spec "$spec" target source condition

        if ! should_manage_condition "$condition"; then
            log_skip "$target ($condition not detected)"
        elif [[ -L "$target" ]]; then
            current_target="$(readlink "$target")"
            if [[ "$target" -ef "$source" ]]; then
                log_skip "$target -> $current_target"
            else
                log_error "$target -> $current_target (expected $source)"
                failed=1
            fi
        elif [[ -e "$target" ]]; then
            if [[ "$target" -ef "$source" ]]; then
                log_skip "$target -> $source (via hardlink)"
            else
                log_error "$target exists but is not managed"
                failed=1
            fi
        else
            log_error "$target missing"
            failed=1
        fi
    done

    return "$failed"
}

check_starship_config() {
    log_section "Starship"

    local config_path="$HOME/.config/starship.toml"

    if [[ -f "$config_path" ]]; then
        log_skip "$config_path"
    else
        log_warn "$config_path not found"
    fi

    if [[ -n "${STARSHIP_CONFIG:-}" && "$STARSHIP_CONFIG" != "$config_path" ]]; then
        log_warn "Current STARSHIP_CONFIG is $STARSHIP_CONFIG; new shells will use $config_path"
    fi
}
