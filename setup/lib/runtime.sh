#!/usr/bin/env bash

ensure_dir() {
    local path="$1"

    if [[ -d "$path" ]]; then
        log_skip "$path"
        return
    fi

    log_action "Create directory $path"
    run_cmd mkdir -p "$path"
}

ensure_local_runtime_file() {
    local runtime_file="$1"
    local example_file="$2"
    local runtime_dir

    runtime_dir="$(dirname "$runtime_file")"
    if [[ ! -d "$runtime_dir" ]]; then
        log_action "Create directory $runtime_dir"
        run_cmd mkdir -p "$runtime_dir"
    fi

    if [[ -f "$runtime_file" ]]; then
        log_skip "$runtime_file"
        return
    fi

    if [[ -f "$example_file" ]]; then
        log_action "Initialize $runtime_file from $example_file"
        run_cmd cp "$example_file" "$runtime_file"
        log_warn "Review $runtime_file and fill local values before use"
        return
    fi

    if $ALLOW_EMPTY_RUNTIME; then
        log_action "Create empty runtime config $runtime_file"
        run_cmd touch "$runtime_file"
        log_warn "Populate $runtime_file before use"
        return
    fi

    log_error "Runtime seed missing: $example_file"
    log_error "Refusing to create empty runtime config: $runtime_file"
    log_warn "Use --allow-empty-runtime only when an empty runtime file is intentional."
    exit 1
}
