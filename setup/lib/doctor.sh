#!/usr/bin/env bash

doctor() {
    local failed=0

    log_section "Doctor"

    preflight
    check_required_commands || failed=1
    check_optional_commands
    check_container_stack
    check_toolchain_stack
    check_directories || failed=1
    check_zsh_plugins || failed=1
    check_local_config_seeds || failed=1
    check_local_config_files
    check_managed_sources || failed=1
    check_managed_links || failed=1
    check_ssh_agent
    check_brew_bundle
    check_runtime_leaks || failed=1
    check_starship_config

    if [[ $failed -ne 0 ]]; then
        log_error "Doctor found issues. Run ./setup/bootstrap.sh to repair managed state."
        exit 1
    fi

    log_skip "Doctor checks passed"
}

check_ssh_agent() {
    log_section "SSH Agent"

    # 1Password is the current truth. Proton Pass remains optional while it is
    # being evaluated. Mirrors the socket precedence in zsh/.zshenv
    # (1Password wins when both agents run).
    local op_socket="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    local proton_socket="${PROTON_PASS_SSH_AUTH_SOCK:-$HOME/.ssh/proton-pass-agent.sock}"
    local vault="${PROTON_PASS_SSH_VAULT:-Work}"

    if [[ -S "$op_socket" ]]; then
        log_skip "1Password agent: $op_socket"
    elif [[ -S "$proton_socket" ]]; then
        log_skip "Proton Pass agent: $proton_socket (vault: $vault)"
    else
        log_warn "No SSH agent socket found; enable the 1Password SSH agent (Settings -> Developer) or run: ppagent start"
    fi
}

check_brew_bundle() {
    log_section "Brew Bundle"

    # Presence-only: self-updating casks run ahead of brew's recorded
    # versions by design, so version drift is not drift.
    if HOMEBREW_BUNDLE_NO_UPGRADE=1 brew bundle check --file="$BREWFILE" >/dev/null 2>&1; then
        log_skip "Brewfile satisfied"
    else
        log_warn "Brewfile drift; inspect with: HOMEBREW_BUNDLE_NO_UPGRADE=1 brew bundle check --verbose --file=$BREWFILE"
    fi
}

check_runtime_leaks() {
    log_section "Runtime Leaks"

    # The invariant: no persistent global runtime state. Outside a project,
    # Python and TypeScript runtimes must not resolve from Homebrew; runtimes
    # are project-scoped via uv and mise.
    local failed=0 leak tool tool_path expected
    local brew_prefix="${HOMEBREW_PREFIX:-/opt/homebrew}"

    for leak in python3 pip3 node npm pnpm bun; do
        if [[ -e "$brew_prefix/bin/$leak" ]]; then
            log_error "$brew_prefix/bin/$leak exists — a formula dragged a runtime onto the host (find it: brew uses --installed <keg>)"
            failed=1
        else
            log_skip "no $brew_prefix/bin/$leak"
        fi
    done

    if [[ -d "$brew_prefix/lib/node_modules" ]] && [[ -n "$(ls -A "$brew_prefix/lib/node_modules" 2>/dev/null)" ]]; then
        log_error "$brew_prefix/lib/node_modules is not empty — global npm residue"
        failed=1
    else
        log_skip "no global npm tree"
    fi

    if [[ -f "$HOME/.config/mise/config.toml" ]] && grep -q '^\[tools\]' "$HOME/.config/mise/config.toml" 2>/dev/null; then
        log_warn "global mise tool pins in ~/.config/mise/config.toml — runtimes should be project-pinned"
    else
        log_skip "no global mise pins"
    fi

    if [[ -d "$HOME/.bun" ]]; then
        log_warn "$HOME/.bun exists — bun should be mise/project-managed"
    fi

    # Standalone copies of brew-managed tools shadow brew and cause drift.
    for tool in uv mise; do
        tool_path="$(command -v "$tool" 2>/dev/null || true)"
        expected="$brew_prefix/bin/$tool"
        if [[ -n "$tool_path" && "$tool_path" != "$expected" ]]; then
            log_warn "$tool resolves to $tool_path (expected $expected) — remove the standalone copy"
        fi
    done

    return "$failed"
}

check_required_commands() {
    log_section "Required Commands"

    local failed=0
    local command_name
    local commands=(
        brew git starship fzf tmux micro zoxide atuin
        eza just prek gitleaks op pass-cli jq rg uv mise
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
    local commands=(amp cursor tailscale)

    for command_name in "${commands[@]}"; do
        if command -v "$command_name" >/dev/null 2>&1; then
            log_skip "$command_name"
        else
            log_warn "$command_name not found"
        fi
    done
}

check_container_stack() {
    log_section "Containers"

    local docker_path docker_target leftover orbstack_xbin
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
}

check_toolchain_stack() {
    log_section "Toolchains"

    local command_name command_path

    if command_path="$(command -v go 2>/dev/null)"; then
        log_skip "go: $command_path"
    else
        log_warn "go not found; install the official Go toolchain when Go projects need it"
    fi

    if command_path="$(command -v rustup 2>/dev/null)"; then
        log_skip "rustup: $command_path"
    else
        log_warn "rustup not found; install from https://rustup.rs when Rust projects need it"
    fi

    for command_name in node pnpm bun; do
        if command_path="$(command -v "$command_name" 2>/dev/null)"; then
            log_warn "$command_name resolves outside a project: $command_path"
        else
            log_skip "$command_name project-scoped via mise"
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

check_local_config_seeds() {
    log_section "Local Config Seeds"

    local failed=0
    local spec _local_config_file example_file _condition
    for spec in "${LOCAL_CONFIG_FILES[@]}"; do
        split_spec "$spec" _local_config_file example_file _condition
        if [[ -f "$example_file" ]]; then
            log_skip "$example_file"
        elif $ALLOW_EMPTY_LOCAL_CONFIG; then
            log_warn "$example_file missing, allowed by --allow-empty-local-config"
        else
            log_error "Runtime seed missing: $example_file"
            failed=1
        fi
    done

    return "$failed"
}

check_local_config_files() {
    log_section "Local Config Files"

    local spec local_config_file example_file condition
    for spec in "${LOCAL_CONFIG_FILES[@]}"; do
        split_spec "$spec" local_config_file example_file condition
        if ! should_manage_condition "$condition"; then
            log_skip "$local_config_file ($condition not detected)"
        elif [[ -f "$local_config_file" ]]; then
            log_skip "$local_config_file"
        elif [[ -f "$example_file" ]]; then
            log_warn "$local_config_file missing; bootstrap can seed it from $example_file"
        else
            log_warn "$local_config_file missing and seed is unavailable"
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
        elif local_config_source_planned "$source"; then
            log_skip "$source (local config seed available)"
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
