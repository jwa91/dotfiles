#!/usr/bin/env bash

doctor_applications() {
    local failed=0

    check_container_stack
    check_herdr_config || failed=1
    check_default_apps || failed=1
    check_command_help

    return "$failed"
}

check_container_stack() {
    log_section "Containers"

    local docker_path docker_target leftover orbstack_xbin
    local podman_found=0
    orbstack_xbin="/Applications/OrbStack.app/Contents/MacOS/xbin"

    if command -v orb >/dev/null 2>&1 || [[ -d "/Applications/OrbStack.app" ]]; then
        log_skip "OrbStack"
    else
        log_warn "OrbStack not found; install with: just brew-sync && just orbstack"
    fi

    if docker_path="$(command -v docker 2>/dev/null)"; then
        docker_target="$docker_path"
        if [[ -L "$docker_path" ]]; then
            docker_target="$(readlink "$docker_path")"
        fi

        if [[ "$docker_path" == "$orbstack_xbin/"* || "$docker_target" == "$orbstack_xbin/"* ]]; then
            log_skip "docker CLI: $docker_path"
        elif [[ "$docker_path" == *"/Docker.app/"* || "$docker_target" == *"/Docker.app/"* ]]; then
            log_warn "docker CLI still points to Docker Desktop: $docker_path -> $docker_target"
        else
            log_warn "docker CLI is not from OrbStack: $docker_path"
        fi
    elif [[ -x "$orbstack_xbin/docker" ]]; then
        log_warn "OrbStack docker CLI exists but is not on this shell PATH; open a new shell or source ~/.zshenv"
    else
        log_warn "docker CLI not found; OrbStack provides it after setup"
    fi

    local docker_desktop_leftovers=(
        "/Applications/Docker.app"
        "$HOME/Library/Group Containers/group.com.docker"
        "$HOME/Library/Containers/com.docker.docker"
        "$HOME/Library/Application Support/Docker Desktop"
        "$HOME/Library/Caches/Docker Desktop"
        "$HOME/.docker/desktop"
        "/Library/LaunchDaemons/com.docker.socket.plist"
        "/Library/PrivilegedHelperTools/com.docker.socket"
        "/Library/LaunchDaemons/com.docker.vmnetd.plist"
        "/Library/PrivilegedHelperTools/com.docker.vmnetd"
    )

    for leftover in "${docker_desktop_leftovers[@]}"; do
        if [[ -e "$leftover" ]]; then
            log_warn "Docker Desktop leftover: $leftover"
        fi
    done

    if [[ ! -e "/Applications/Docker.app" ]]; then
        log_skip "Docker Desktop app absent"
    fi

    local podman_leftovers=(
        "/Applications/Podman Desktop.app"
        "/Applications/Podman.app"
        "/opt/podman"
        "$HOME/.config/containers"
        "$HOME/.local/share/containers/podman"
        "$HOME/.local/share/containers/podman-desktop"
        "$HOME/Library/Application Support/containers"
        "$HOME/Library/Application Support/Podman Desktop"
    )

    for leftover in "${podman_leftovers[@]}"; do
        if [[ -e "$leftover" ]]; then
            log_warn "Podman competing state: $leftover"
            podman_found=1
        fi
    done

    if [[ -x "/opt/podman/bin/podman" ]] \
        && command -v jq >/dev/null 2>&1 \
        && /opt/podman/bin/podman machine list --format json 2>/dev/null \
            | jq -e 'any(.[]; .Running == true)' >/dev/null; then
        log_warn "Podman machine is running while OrbStack owns containers"
        podman_found=1
    fi

    if [[ "$podman_found" -eq 0 ]]; then
        log_skip "Podman absent"
    fi
}

check_herdr_config() {
    log_section "Herdr"

    local failed=0

    if ! command -v herdr >/dev/null 2>&1; then
        log_warn "herdr not found; run: ./setup/init.sh standalone"
        return 0
    fi

    if herdr config check >/dev/null 2>&1; then
        log_skip "Herdr config valid"
    else
        log_error "Herdr config invalid; run: herdr config check"
        failed=1
    fi

    if [[ -f "$HOME/.zfunc/_herdr" ]]; then
        log_skip "Herdr zsh completion"
    else
        log_warn "Herdr zsh completion missing; run: ./setup/init.sh zsh"
    fi

    return "$failed"
}

check_default_apps() {
    log_section "Default Applications"

    local failed=0 extension handler
    local representative_extensions=(go json md rs sh toml tsx txt)

    if ! is_zed_installed; then
        log_warn "Zed is not installed; default application checks skipped"
        return 0
    fi

    if ! command -v duti >/dev/null 2>&1; then
        log_error "duti not found; run: ./setup/init.sh homebrew"
        return 1
    fi

    for extension in "${representative_extensions[@]}"; do
        handler="$(duti -x "$extension" 2>/dev/null | tail -n 1)"
        if [[ "$handler" == "dev.zed.Zed" ]]; then
            log_skip ".$extension -> Zed"
        else
            log_error ".$extension handler is ${handler:-unknown}; run: ./setup/set.sh default-apps"
            failed=1
        fi
    done

    return "$failed"
}

check_command_help() {
    log_section "Command Help"

    local community_dir="${CHEAT_COMMUNITY_DIR:-$HOME/.config/cheat/cheatsheets/community}"

    if [[ -d "$community_dir/.git" ]]; then
        log_skip "cheat community sheets: $community_dir"
    else
        log_warn "cheat community sheets missing; run: ./setup/init.sh command-help"
    fi

    if command -v tldr >/dev/null 2>&1; then
        log_skip "tldr client"
    else
        log_warn "tldr client missing; run: ./setup/init.sh homebrew"
    fi
}
