#!/usr/bin/env bash
# Converge managed links.

conflict_error() {
    local target="$1"
    local source="$2"
    local backup_path

    backup_path="${target}.backup.$(date +%Y%m%d%H%M%S)"

    log_error "Target exists and is not a symlink: $target"
    printf '\nResolve conflict with:\n'
    printf '  mv "%s" "%s"\n' "$target" "$backup_path"
    printf '  ln -s "%s" "%s"\n\n' "$source" "$target"
    printf 'Then rerun: ./setup/set.sh links\n'
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

    if $RESET_LINKS; then
        reset_symlinks
    fi

    ensure_local_config_files
    link_managed_configs
}
