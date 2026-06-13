#!/usr/bin/env bash

doctor() {
    local failed=0

    log_section "Doctor"

    preflight
    check_required_commands || failed=1
    check_optional_commands
    check_container_stack
    check_toolchain_stack || failed=1
    check_directories || failed=1
    check_zsh_plugins || failed=1
    check_local_config_seeds || failed=1
    check_local_config_files
    check_managed_sources || failed=1
    check_managed_links || failed=1
    check_command_help
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

    # The invariant: Homebrew owns managers only. uv owns Python projects;
    # mise owns Go, Rust, Node, pnpm, and Bun versions.
    local failed=0 leak tool tool_path expected cargo_entry cargo_drift
    local brew_prefix="${HOMEBREW_PREFIX:-/opt/homebrew}"

    for leak in python3 pip3 node npm pnpm bun go rustup rustc cargo; do
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

    if [[ -d "$HOME/.bun" ]]; then
        log_warn "$HOME/.bun exists — bun should be mise/project-managed"
    fi

    if [[ -d "$HOME/.local/share/go" ]]; then
        log_error "$HOME/.local/share/go exists — direct Go install should be removed; mise owns Go"
        failed=1
    else
        log_skip "no direct Go install in ~/.local/share/go"
    fi

    if [[ -d "/usr/local/go" ]]; then
        log_error "/usr/local/go exists — direct/admin Go install should be removed; mise owns Go"
        failed=1
    else
        log_skip "no direct Go install in /usr/local/go"
    fi

    if [[ -d "$HOME/go/bin" ]] && [[ -n "$(ls -A "$HOME/go/bin" 2>/dev/null)" ]]; then
        log_error "$HOME/go/bin is not empty — global Go CLI installs should be managed by mise or Brewfile"
        failed=1
    else
        log_skip "no global Go CLI bin"
    fi

    cargo_drift=0
    if [[ -d "$HOME/.cargo/bin" ]]; then
        for cargo_entry in "$HOME/.cargo/bin"/*; do
            [[ -e "$cargo_entry" ]] || continue
            if [[ "$(basename "$cargo_entry")" == "rustup" ]]; then
                continue
            fi
            if [[ -L "$cargo_entry" && "$(readlink "$cargo_entry")" == "rustup" ]]; then
                continue
            fi
            log_error "$cargo_entry is not a rustup shim — global Cargo CLIs should be managed by mise or Brewfile"
            cargo_drift=1
        done
    fi
    if [[ "$cargo_drift" -eq 0 ]]; then
        log_skip "cargo bin contains only rustup shims"
    else
        failed=1
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
        eza just prek gitleaks op pass-cli jq rg uv mise cheat tldr
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
    log_section "Mise Toolchains"

    local failed=0 command_name command_path current version_output undeclared_mise_tools undeclared_tool

    if [[ -f "$HOME/.config/mise/config.toml" ]]; then
        log_skip "$HOME/.config/mise/config.toml"
    else
        log_error "$HOME/.config/mise/config.toml missing; bootstrap should link config/mise/config.toml"
        failed=1
    fi

    if current="$(mise current go 2>/dev/null)" && [[ -n "$current" ]]; then
        log_skip "mise go: $current"
    else
        log_error "mise go baseline missing; expected config/mise/config.toml to define it"
        failed=1
    fi

    if version_output="$(mise exec -- go version 2>/dev/null)"; then
        log_skip "$version_output"
    else
        log_error "go is not available through mise; run: mise install go"
        failed=1
    fi

    if current="$(mise current rust 2>/dev/null)" && [[ -n "$current" ]]; then
        log_skip "mise rust: $current"
    else
        log_error "mise rust baseline missing; expected config/mise/config.toml to define it"
        failed=1
    fi

    if version_output="$(mise exec -- rustc --version 2>/dev/null)"; then
        log_skip "$version_output"
    else
        log_error "rustc is not available through mise; run: mise install rust"
        failed=1
    fi

    if version_output="$(mise exec -- cargo --version 2>/dev/null)"; then
        log_skip "$version_output"
    else
        log_error "cargo is not available through mise; run: mise install rust"
        failed=1
    fi

    for command_name in node pnpm bun; do
        if command_path="$(command -v "$command_name" 2>/dev/null)"; then
            log_warn "$command_name resolves outside a project: $command_path"
        else
            log_skip "$command_name project-scoped via mise"
        fi
    done

    if command -v jq >/dev/null 2>&1; then
        if undeclared_mise_tools="$(mise ls --json 2>/dev/null | jq -r '
            to_entries[]
            | .key as $tool
            | .value[]?
            | select(.installed == true and (.source? | not))
            | "\($tool)@\(.version)"
        ')"; then
            if [[ -n "$undeclared_mise_tools" ]]; then
                while IFS= read -r undeclared_tool; do
                    log_error "mise tool installed without repo/project config source: $undeclared_tool"
                    failed=1
                done <<< "$undeclared_mise_tools"
            else
                log_skip "no undeclared mise-installed tools"
            fi
        else
            log_warn "Could not inspect undeclared mise-installed tools"
        fi
    else
        log_warn "jq missing; cannot inspect undeclared mise-installed tools"
    fi

    return "$failed"
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
            log_error "Local config seed missing: $example_file"
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
    while IFS= read -r spec; do
        split_spec "$spec" target source _condition
        if [[ -e "$source" ]]; then
            log_skip "$source"
        elif local_config_source_planned "$source"; then
            log_skip "$source (local config seed available)"
        else
            log_error "Managed source missing for $target: $source"
            failed=1
        fi
    done < <(managed_link_specs)

    return "$failed"
}

check_managed_links() {
    log_section "Managed Links"

    local failed=0
    local spec target source condition current_target

    while IFS= read -r spec; do
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
    done < <(managed_link_specs)

    return "$failed"
}

check_command_help() {
    log_section "Command Help"

    local community_dir="${CHEAT_COMMUNITY_DIR:-$HOME/.config/cheat/cheatsheets/community}"

    if [[ -d "$community_dir/.git" ]]; then
        log_skip "cheat community sheets: $community_dir"
    else
        log_warn "cheat community sheets missing; run: just help"
    fi

    if command -v tldr >/dev/null 2>&1; then
        log_skip "tldr client"
    else
        log_warn "tldr client missing; run: just brew-sync"
    fi
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
