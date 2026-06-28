#!/usr/bin/env bash

MANAGED_LINKS=(
    "$HOME/.gitconfig|$GIT_DIR/config|always"
    "$HOME/.config/git/commit_template.txt|$GIT_DIR/commit_template.txt|always"
    "$HOME/.config/git/ignore|$GIT_DIR/ignore|always"
    "$HOME/.zshrc|$ZSH_DIR/.zshrc|always"
    "$HOME/.zshenv|$ZSH_DIR/.zshenv|always"
    "$HOME/.zprofile|$ZSH_DIR/.zprofile|always"
    "$HOME/.config/ghostty|$CONFIG_DIR/ghostty|always"
    "$HOME/.config/starship.toml|$CONFIG_DIR/starship.toml|always"
    "$HOME/.claude/settings.json|$CONFIG_DIR/claude-code/settings.json|always"
    "$HOME/.config/cheat/conf.yml|$CONFIG_DIR/cheat/conf.yml|always"
    "$HOME/.config/cheat/cheatsheets/personal|$CONFIG_DIR/cheat/cheatsheets|always"
    "$HOME/.config/eza|$CONFIG_DIR/eza|always"
    "$HOME/.config/broot/conf.hjson|$CONFIG_DIR/broot/conf.hjson|always"
    "$HOME/.config/broot/verbs.hjson|$CONFIG_DIR/broot/verbs.hjson|always"
    "$HOME/.config/broot/skins|$CONFIG_DIR/broot/skins|always"
    "$HOME/.config/atuin/config.toml|$CONFIG_DIR/atuin/config.toml|always"
    "$HOME/.config/mise/config.toml|$CONFIG_DIR/mise/config.toml|always"
    "$HOME/.tmux.conf|$CONFIG_DIR/tmux/tmux.conf|always"
    "$HOME/Library/Application Support/Cursor/User/settings.json|$CONFIG_DIR/cursor/settings.json|cursor"
    "$HOME/Library/Application Support/Cursor/User/keybindings.json|$CONFIG_DIR/cursor/keybindings.json|cursor"
    "$HOME/.cursor/mcp.json|$DOTFILES_LOCAL_CONFIG_DIR/cursor/mcp.json|cursor"
)

managed_executable_sources() {
    local source

    if [[ -d "$DOTFILES_DIR/bin" ]]; then
        for source in "$DOTFILES_DIR/bin"/*; do
            [[ -f "$source" && -x "$source" ]] || continue
            printf '%s\n' "$source"
        done
    fi

    if [[ -d "$DOTFILES_DIR/bin/shims" ]]; then
        for source in "$DOTFILES_DIR/bin/shims"/*; do
            [[ -f "$source" && -x "$source" ]] || continue
            printf '%s\n' "$source"
        done
    fi
}

managed_link_specs() {
    local source

    printf '%s\n' "${MANAGED_LINKS[@]}"

    while IFS= read -r source; do
        printf '%s|%s|always\n' "$HOME/.local/bin/$(basename "$source")" "$source"
    done < <(managed_executable_sources)
}

LOCAL_CONFIG_FILES=(
    "$HOME/.gitconfig.local|$GIT_DIR/config.local.example|always"
    "$DOTFILES_LOCAL_CONFIG_DIR/cursor/mcp.json|$CONFIG_DIR/cursor/mcp.example.json|cursor"
)

is_cursor_installed() {
    if command -v cursor >/dev/null 2>&1; then
        return 0
    fi

    [[ -d "/Applications/Cursor.app" || -d "$HOME/Applications/Cursor.app" ]]
}

should_manage_condition() {
    local condition="$1"

    case "$condition" in
        always)
            return 0
            ;;
        cursor)
            is_cursor_installed
            ;;
        *)
            log_error "Unknown managed-link condition: $condition"
            exit 1
            ;;
    esac
}

split_spec() {
    local spec="$1"
    local target_ref="$2"
    local source_ref="$3"
    local condition_ref="$4"
    local parsed_target parsed_source parsed_condition

    IFS='|' read -r parsed_target parsed_source parsed_condition <<< "$spec"
    printf -v "$target_ref" '%s' "$parsed_target"
    printf -v "$source_ref" '%s' "$parsed_source"
    printf -v "$condition_ref" '%s' "$parsed_condition"
}

local_config_source_planned() {
    local source="$1"
    local spec local_config_file example_file condition

    for spec in "${LOCAL_CONFIG_FILES[@]}"; do
        split_spec "$spec" local_config_file example_file condition
        if [[ "$local_config_file" == "$source" && -f "$example_file" ]]; then
            return 0
        fi
    done

    return 1
}

conflict_error() {
    local target="$1"
    local source="$2"
    local backup_path

    backup_path="${target}.backup.$(date +%Y%m%d%H%M%S)"

    log_error "Target exists and is not a symlink: $target"
    echo ""
    echo "Resolve conflict with:"
    echo "  mv \"$target\" \"$backup_path\""
    echo "  ln -s \"$source\" \"$target\""
    echo ""
    echo "Then rerun: ./setup/bootstrap.sh --only links"
    exit 1
}

managed_directory_can_be_replaced() {
    local target="$1"
    local source="$2"
    local entry source_entry entry_name

    [[ -d "$target" && ! -L "$target" && -d "$source" ]] || return 1

    while IFS= read -r -d '' entry; do
        entry_name="$(basename "$entry")"
        source_entry="$source/$entry_name"

        if [[ ! -e "$source_entry" || ! "$entry" -ef "$source_entry" ]]; then
            return 1
        fi
    done < <(find "$target" -mindepth 1 -maxdepth 1 -print0)

    return 0
}

migrate_managed_directory_to_symlink() {
    local target="$1"
    local source="$2"
    local backup_path

    backup_path="${target}.backup.$(date +%Y%m%d%H%M%S)"

    log_action "Replace managed directory $target with symlink to $source"
    run_cmd mv "$target" "$backup_path"
    run_cmd ln -s "$source" "$target"
    log_warn "Backed up previous managed directory to $backup_path"
}

ensure_symlink() {
    local target="$1"
    local source="$2"
    local parent_dir

    if [[ ! -e "$source" ]]; then
        if $DRY_RUN && local_config_source_planned "$source"; then
            log_warn "Managed source will be initialized from local config seed: $source"
        else
            log_error "Managed source missing: $source"
            exit 1
        fi
    fi

    parent_dir="$(dirname "$target")"
    if [[ ! -d "$parent_dir" ]]; then
        log_action "Create directory $parent_dir"
        run_cmd mkdir -p "$parent_dir"
    fi

    if [[ -L "$target" ]]; then
        if [[ "$target" -ef "$source" ]]; then
            log_skip "$target -> $source"
        else
            log_action "Update symlink $target -> $source"
            run_cmd ln -sfn "$source" "$target"
        fi
    elif [[ -e "$target" ]]; then
        if [[ "$target" -ef "$source" ]]; then
            log_skip "$target -> $source (via hardlink)"
        elif managed_directory_can_be_replaced "$target" "$source"; then
            migrate_managed_directory_to_symlink "$target" "$source"
        else
            conflict_error "$target" "$source"
        fi
    else
        log_action "Create symlink $target -> $source"
        run_cmd ln -s "$source" "$target"
    fi
}

reset_symlinks() {
    log_section "Reset Symlinks"

    local spec target source condition
    while IFS= read -r spec; do
        split_spec "$spec" target source condition
        if [[ -L "$target" ]]; then
            log_action "Remove symlink $target"
            run_cmd rm "$target"
        elif [[ -e "$target" ]]; then
            log_skip "$target (not a symlink, leaving alone)"
        fi
    done < <(managed_link_specs)
}

ensure_local_config_files() {
    log_section "Local Configs"

    local spec local_config_file example_file condition
    for spec in "${LOCAL_CONFIG_FILES[@]}"; do
        split_spec "$spec" local_config_file example_file condition
        if should_manage_condition "$condition"; then
            ensure_local_config_file "$local_config_file" "$example_file"
        else
            log_skip "$local_config_file ($condition not detected)"
        fi
    done
}

link_managed_configs() {
    local spec target source condition
    while IFS= read -r spec; do
        split_spec "$spec" target source condition
        if should_manage_condition "$condition"; then
            ensure_symlink "$target" "$source"
        else
            log_skip "$target ($condition not detected)"
        fi
    done < <(managed_link_specs)
}

link_configs() {
    log_section "Link Dotfiles & App Configs"

    if $SKIP_LINK; then
        log_skip "linking step (--no-link)"
        return
    fi

    if $RESET_LINKS; then
        reset_symlinks
    fi

    ensure_local_config_files
    link_managed_configs
}
