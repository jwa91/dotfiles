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

    local failed=0

    # ADR 0002 scopes shim authority to humans, scripts, and agents. Interactive
    # zsh covers humans. `zsh -c` is what scripts and agents actually invoke, and
    # it reads only .zshenv, so it can regress on its own — checking one does not
    # cover the other.
    check_shim_authority_in "interactive zsh" -ic || failed=1
    check_shim_authority_in "noninteractive zsh" -c || failed=1

    return "$failed"
}

check_shim_authority_in() {
    local label="$1"
    local zsh_flag="$2"
    local failed=0 output command_name command_path

    if ! command -v zsh >/dev/null 2>&1; then
        log_error "zsh missing; cannot verify $label shim authority"
        return 1
    fi

    # env -i is the point of this check. Doctor runs with ~/.local/bin already
    # on PATH, so an inheriting probe would pass no matter what the zsh startup
    # files do, and would keep passing after a regression. Starting from a bare
    # PATH forces the startup files to build the shim PATH themselves.
    if ! output="$(
        env -i \
            HOME="$HOME" \
            PATH="/usr/bin:/bin" \
            TERM=xterm-256color \
            DOTFILES_DIR="$DOTFILES_DIR" \
            zsh "$zsh_flag" '
            for command_name in node npm npx pnpm yarn bun go cargo rustup; do
                printf "%s\t%s\n" "$command_name" "$(command -v "$command_name" 2>/dev/null || true)"
            done
        ' 2>/dev/null
    )"; then
        log_error "$label failed while checking shim authority"
        return 1
    fi

    while IFS=$'\t' read -r command_name command_path; do
        [[ -n "$command_name" ]] || continue

        if is_dotfiles_shim_path "$command_name" "$command_path"; then
            log_skip "$label $command_name shim: $command_path"
        else
            log_error "$label $command_name bypasses dotfiles shim: ${command_path:-missing}"
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
