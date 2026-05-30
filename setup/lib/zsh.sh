#!/usr/bin/env bash

setup_zsh_environment() {
    log_section "Zsh Environment"

    ensure_dir "$HOME/.zsh_plugins"
    ensure_dir "$HOME/developer"
    ensure_dir "$HOME/.local/bin"

    local plugins=(
        "zsh-autosuggestions:https://github.com/zsh-users/zsh-autosuggestions"
        "zsh-syntax-highlighting:https://github.com/zsh-users/zsh-syntax-highlighting"
    )

    local plugin name url path
    for plugin in "${plugins[@]}"; do
        name="${plugin%%:*}"
        url="${plugin#*:}"
        path="$HOME/.zsh_plugins/$name"

        if [[ -d "$path" ]]; then
            if $UPDATE_PLUGINS; then
                log_action "Update $name"
                run_cmd git -C "$path" pull --ff-only
            else
                log_skip "$path"
            fi
        else
            log_action "Clone $name"
            run_cmd git clone --depth 1 "$url" "$path"
        fi
    done
}
