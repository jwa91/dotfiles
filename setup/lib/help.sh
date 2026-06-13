#!/usr/bin/env bash

setup_command_help() {
    log_section "Command Help"

    local community_repo="${CHEAT_COMMUNITY_REPO:-https://github.com/cheat/cheatsheets.git}"
    local community_dir="${CHEAT_COMMUNITY_DIR:-$HOME/.config/cheat/cheatsheets/community}"
    local community_parent
    community_parent="$(dirname "$community_dir")"

    ensure_dir "$community_parent"

    if [[ -d "$community_dir/.git" ]]; then
        log_action "Update cheat community sheets"
        if ! $DRY_RUN && ! git -C "$community_dir" pull --ff-only; then
            log_warn "Could not update $community_dir"
        elif $DRY_RUN; then
            run_cmd git -C "$community_dir" pull --ff-only
        fi
    elif [[ -e "$community_dir" ]]; then
        log_warn "$community_dir exists but is not a git checkout; leaving it alone"
    else
        log_action "Clone cheat community sheets"
        if ! $DRY_RUN && ! git clone --depth 1 "$community_repo" "$community_dir"; then
            log_warn "Could not clone $community_repo"
        elif $DRY_RUN; then
            run_cmd git clone --depth 1 "$community_repo" "$community_dir"
        fi
    fi

    if command -v tldr >/dev/null 2>&1; then
        log_action "Update tldr cache"
        if ! $DRY_RUN && ! tldr --update; then
            log_warn "Could not update tldr cache"
        elif $DRY_RUN; then
            run_cmd tldr --update
        fi
    else
        log_warn "tldr not found; run brew bundle after adding tlrc"
    fi
}
