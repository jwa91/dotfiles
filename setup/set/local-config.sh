#!/usr/bin/env bash
# Converge machine-local configuration seeds.

ensure_local_config_file() {
    local local_config_file="$1"
    local example_file="$2"
    local local_config_dir

    local_config_dir="$(dirname "$local_config_file")"
    if [[ ! -d "$local_config_dir" ]]; then
        log_action "Create directory $local_config_dir"
        run_cmd mkdir -p "$local_config_dir"
    fi

    if [[ -f "$local_config_file" ]]; then
        log_skip "$local_config_file"
        return
    fi

    if [[ -f "$example_file" ]]; then
        log_action "Initialize $local_config_file from $example_file"
        run_cmd cp "$example_file" "$local_config_file"
        log_warn "Review $local_config_file and fill local values before use"
        return
    fi

    if $ALLOW_EMPTY_LOCAL_CONFIG; then
        log_action "Create empty local config $local_config_file"
        run_cmd touch "$local_config_file"
        log_warn "Populate $local_config_file before use"
        return
    fi

    log_error "Local config seed missing: $example_file"
    log_error "Refusing to create empty local config: $local_config_file"
    log_warn "Use --allow-empty-local-config only when an empty local config is intentional."
    exit 1
}
