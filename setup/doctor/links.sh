#!/usr/bin/env bash

doctor_links() {
    local failed=0

    check_local_config_seeds || failed=1
    check_local_config_files
    check_managed_sources || failed=1
    check_managed_links || failed=1

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
            log_warn "$local_config_file missing; run: ./setup/set.sh local-config"
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
