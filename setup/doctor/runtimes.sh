#!/usr/bin/env bash

doctor_runtimes() {
    local failed=0

    check_python_policy || failed=1
    check_toolchain_stack || failed=1
    check_runtime_leaks || failed=1

    return "$failed"
}

check_python_policy() {
    log_section "Python Policy"

    local failed=0 command_name command_path

    if [[ "${UV_MANAGED_PYTHON:-}" == "1" ]]; then
        log_skip "UV_MANAGED_PYTHON=1"
    else
        log_error "UV_MANAGED_PYTHON must be 1 so uv cannot silently use system/framework Python"
        failed=1
    fi

    for command_name in python python3 pip pip3; do
        if command_path="$(command -v "$command_name" 2>/dev/null)"; then
            if is_dotfiles_shim_path "$command_name" "$command_path"; then
                log_skip "$command_name shim: $command_path"
            else
                log_error "$command_name resolves outside the dotfiles shim: $command_path"
                failed=1
            fi
        else
            log_error "$command_name shim missing; run: ./setup/set.sh links"
            failed=1
        fi
    done

    if [[ "${UV_PYTHON_DOWNLOADS:-}" == "never" ]]; then
        log_skip "UV_PYTHON_DOWNLOADS=never"
    else
        log_skip "uv may download managed Python runtimes on demand"
    fi

    return "$failed"
}

check_runtime_leaks() {
    log_section "Runtime Leaks"

    # Homebrew owns machine CLIs; uv owns Python, mise owns runtime versions, and packageManager + Corepack own pnpm versions.
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

    if [[ -n "${BUN_INSTALL:-}" || -e "$HOME/.bun/bin/bun" ]]; then
        log_warn "official Bun installer state found; Bun runtime should be mise-owned"
    elif [[ -d "$HOME/.bun/install/cache" ]]; then
        log_skip "bun cache only"
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

    for tool in uv mise; do
        tool_path="$(command -v "$tool" 2>/dev/null || true)"
        expected="$brew_prefix/bin/$tool"
        if [[ -n "$tool_path" && "$tool_path" != "$expected" ]]; then
            log_warn "$tool resolves to $tool_path (expected $expected) — remove the standalone copy"
        fi
    done

    return "$failed"
}

mise_config_dirs() {
    local developer_dir="${DEV_DIR:-$HOME/developer}"

    printf '%s\n' "$DOTFILES_DIR"

    if [[ -d "$developer_dir" ]]; then
        find "$developer_dir" \
            \( -name .git -o -name node_modules -o -name .build \) -prune -o \
            -type f \( \
                -name mise.toml -o \
                -name .mise.toml -o \
                -name .tool-versions -o \
                -name .go-version -o \
                -name .node-version -o \
                -name .rust-version \
            \) -exec dirname {} \; | sort -u
    fi
}

mise_installed_tools() {
    mise ls --json 2>/dev/null | jq -r '
        to_entries[]
        | .key as $tool
        | .value[]?
        | select(.installed == true)
        | "\($tool)@\(.version)"
    ' | sort -u
}

mise_declared_installed_tools() {
    local mise_dir

    while IFS= read -r mise_dir; do
        mise -C "$mise_dir" ls --json 2>/dev/null | jq -r '
            to_entries[]
            | .key as $tool
            | .value[]?
            | select(.installed == true and (.source.path? != null))
            | "\($tool)@\(.version)"
        '
    done < <(mise_config_dirs) | sort -u
}

is_harness_owned_tool_path() {
    case "$1" in
        "$HOME/.cache/codex-runtimes/"*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

is_dotfiles_shim_path() {
    local command_name="$1"
    local command_path="$2"
    local expected_path="$HOME/.local/bin/$command_name"
    local source_path="$DOTFILES_DIR/bin/shims/$command_name"

    [[ "$command_path" == "$expected_path" && -e "$source_path" && "$command_path" -ef "$source_path" ]]
}

check_toolchain_stack() {
    log_section "Mise Toolchains"

    local failed=0 command_name command_path current version_output installed_mise_tools declared_mise_tools undeclared_mise_tools undeclared_tool

    if [[ -f "$HOME/.config/mise/config.toml" ]]; then
        log_skip "$HOME/.config/mise/config.toml"
    else
        log_error "$HOME/.config/mise/config.toml missing; run: ./setup/set.sh links"
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
        log_error "go is not available through mise; run: ./setup/init.sh toolchains"
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
        log_error "rustc is not available through mise; run: ./setup/init.sh toolchains"
        failed=1
    fi

    if version_output="$(mise exec -- cargo --version 2>/dev/null)"; then
        log_skip "$version_output"
    else
        log_error "cargo is not available through mise; run: ./setup/init.sh toolchains"
        failed=1
    fi

    if current="$(mise current node 2>/dev/null)" && [[ -n "$current" ]]; then
        log_skip "mise Node: $current"
    else
        log_error "mise Node baseline missing; expected config/mise/config.toml to define it"
        failed=1
    fi

    if version_output="$(mise exec -- node --version 2>/dev/null)"; then
        log_skip "Node $version_output"
    else
        log_error "Node is not available through mise; run: ./setup/init.sh toolchains"
        failed=1
    fi

    if version_output="$(mise exec -- corepack --version 2>/dev/null)"; then
        log_skip "Corepack $version_output"
    else
        log_error "Corepack is not available through mise-owned Node"
        failed=1
    fi

    if current="$(mise current bun 2>/dev/null)" && [[ -n "$current" ]]; then
        log_skip "mise Bun: $current"
    else
        log_error "mise Bun baseline missing; expected config/mise/config.toml to define it"
        failed=1
    fi

    if version_output="$(mise exec -- bun --version 2>/dev/null)"; then
        log_skip "Bun $version_output"
    else
        log_error "Bun is not available through mise; run: ./setup/init.sh toolchains"
        failed=1
    fi

    for command_name in node npm npx pnpm yarn bun go cargo rustup; do
        if command_path="$(command -v "$command_name" 2>/dev/null)"; then
            if is_dotfiles_shim_path "$command_name" "$command_path"; then
                log_skip "$command_name shim: $command_path"
            elif is_harness_owned_tool_path "$command_path"; then
                log_error "$command_name resolves to harness-owned runtime before dotfiles shim: $command_path"
                failed=1
            else
                log_error "$command_name resolves outside the dotfiles shim: $command_path"
                failed=1
            fi
        else
            log_error "$command_name shim missing; run: ./setup/set.sh links"
            failed=1
        fi
    done

    if command -v jq >/dev/null 2>&1; then
        if installed_mise_tools="$(mise_installed_tools)" && declared_mise_tools="$(mise_declared_installed_tools)"; then
            undeclared_mise_tools="$(comm -23 <(printf '%s\n' "$installed_mise_tools") <(printf '%s\n' "$declared_mise_tools"))"
            if [[ -n "$undeclared_mise_tools" ]]; then
                while IFS= read -r undeclared_tool; do
                    log_error "mise tool installed without repo/project config owner: $undeclared_tool"
                    failed=1
                done <<< "$undeclared_mise_tools"
            else
                log_skip "all installed mise tools have repo/project owners"
            fi
        else
            log_warn "Could not inspect undeclared mise-installed tools"
        fi
    else
        log_warn "jq missing; cannot inspect undeclared mise-installed tools"
    fi

    return "$failed"
}
