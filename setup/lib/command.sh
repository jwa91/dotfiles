#!/usr/bin/env bash

run_cmd() {
    if $DRY_RUN; then
        echo -e "${YELLOW}WOULD:${NC} $*"
    else
        "$@"
    fi
}

ensure_dir() {
    local path="$1"

    if [[ -d "$path" ]]; then
        log_skip "$path"
        return
    fi

    log_action "Create directory $path"
    run_cmd mkdir -p "$path"
}
