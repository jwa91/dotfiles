#!/usr/bin/env bash
# Install mise toolchains from the tracked global configuration.

install_mise_toolchains() {
    log_section "Mise Toolchains"

    local mise_config="$CONFIG_DIR/mise/config.toml"

    if ! command -v mise >/dev/null 2>&1; then
        if $DRY_RUN; then
            log_warn "mise is missing now, but init homebrew would install it before toolchains"
            return
        fi

        log_error "mise is missing; run: ./setup/init.sh homebrew"
        exit 1
    fi

    log_action "Trust tracked mise config"
    run_cmd mise trust "$mise_config"

    log_action "Install toolchains from tracked mise config"
    if $DRY_RUN; then
        run_cmd env MISE_GLOBAL_CONFIG_FILE="$mise_config" mise install
    else
        MISE_GLOBAL_CONFIG_FILE="$mise_config" mise install
    fi
}
