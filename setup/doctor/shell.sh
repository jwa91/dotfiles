#!/usr/bin/env bash

doctor_shell() {
    local failed=0

    check_zsh_shim_authority || failed=1
    check_zsh_plugins || failed=1
    check_starship_config

    return "$failed"
}

check_zsh_shim_authority() {
    log_section "Zsh Shim Authority"

    local failed=0 output command_name command_path

    if ! command -v zsh >/dev/null 2>&1; then
        log_error "zsh missing; cannot verify interactive shim authority"
        return 1
    fi

    if ! output="$(
        TERM=xterm-256color zsh -ic '
            for command_name in node npm npx pnpm yarn bun go cargo rustup; do
                printf "%s\t%s\n" "$command_name" "$(command -v "$command_name" 2>/dev/null || true)"
            done
        ' 2>/dev/null
    )"; then
        log_error "interactive zsh failed while checking shim authority"
        return 1
    fi

    while IFS=$'\t' read -r command_name command_path; do
        [[ -n "$command_name" ]] || continue

        if is_dotfiles_shim_path "$command_name" "$command_path"; then
            log_skip "interactive zsh $command_name shim: $command_path"
        else
            log_error "interactive zsh $command_name bypasses dotfiles shim: ${command_path:-missing}"
            failed=1
        fi
    done <<< "$output"

    return "$failed"
}

check_zsh_plugins() {
    log_section "Zsh Plugins"

    local failed=0
    local plugin plugin_path
    local plugin_root="$ZSH_PLUGINS_DIR"
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
