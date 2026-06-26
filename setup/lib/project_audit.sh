#!/usr/bin/env bash

project_audit_package_json_files() {
    local developer_dir="$1"

    find "$developer_dir" \
        \( \
            -name .git -o \
            -name node_modules -o \
            -name vendor -o \
            -name dist -o \
            -name build -o \
            -name .next -o \
            -name .output -o \
            -path '*/.claude/worktrees' \
        \) -prune -o \
        -name package.json -type f -print
}

project_audit_is_ignored() {
    local developer_dir="$1"
    local project_dir="$2"
    local ignore_file="${PROJECT_AUDIT_IGNORE_FILE:-$DOTFILES_DIR/setup/project-audit-ignore.txt}"
    local relative_path pattern

    [[ -f "$ignore_file" ]] || return 1

    relative_path="${project_dir#"$developer_dir"/}"

    while IFS= read -r pattern || [[ -n "$pattern" ]]; do
        [[ -z "$pattern" || "$pattern" == \#* ]] && continue

        if [[ "$relative_path" == "$pattern" || "$relative_path" == "$pattern"/* ]]; then
            return 0
        fi
    done < "$ignore_file"

    return 1
}

project_audit_package_manager() {
    jq -r '.packageManager // empty' "$1" 2>/dev/null
}

project_audit_node_pin() {
    local project_dir="$1"
    local mise_file="$project_dir/mise.toml"

    mise -C "$project_dir" ls node --json 2>/dev/null | jq -r --arg source "$mise_file" '
        map(select(.active == true and .source.type == "mise.toml" and .source.path == $source))
        | .[0].requested_version // empty
    '
}

project_audit_mise_tracked() {
    local project_dir="$1"
    local mise_file="$project_dir/mise.toml"
    local git_root relative_mise

    git_root="$(git -C "$project_dir" rev-parse --show-toplevel 2>/dev/null)" || return 2
    relative_mise="${mise_file#"$git_root"/}"

    git -C "$git_root" ls-files --error-unmatch -- "$relative_mise" >/dev/null 2>&1
}

project_audit_check_node_version_files() {
    local project_dir="$1"
    local relative_path="$2"
    local failed=0

    if [[ -f "$project_dir/.nvmrc" ]]; then
        log_error "$relative_path: .nvmrc competes with mise.toml"
        failed=1
    fi

    if [[ -f "$project_dir/.node-version" ]]; then
        log_error "$relative_path: .node-version competes with mise.toml"
        failed=1
    fi

    if [[ -f "$project_dir/.tool-versions" ]] && grep -Eq '^[[:space:]]*(node|nodejs)[[:space:]]' "$project_dir/.tool-versions"; then
        log_error "$relative_path: .tool-versions contains a Node pin"
        failed=1
    fi

    return "$failed"
}

project_audit_check_project() {
    local developer_dir="$1"
    local package_json="$2"
    local project_dir package_manager relative_path node_pin failed=0

    project_dir="$(dirname "$package_json")"
    relative_path="${project_dir#"$developer_dir"/}"
    package_manager="$(project_audit_package_manager "$package_json")"

    [[ -n "$package_manager" ]] || return 0

    if project_audit_is_ignored "$developer_dir" "$project_dir"; then
        log_skip "ignored: $relative_path ($package_manager)"
        return 0
    fi

    if [[ ! -f "$project_dir/mise.toml" ]]; then
        log_error "$relative_path: packageManager $package_manager but missing mise.toml"
        return 1
    fi

    if ! project_audit_check_node_version_files "$project_dir" "$relative_path"; then
        failed=1
    fi

    node_pin="$(project_audit_node_pin "$project_dir")"
    if [[ ! "$node_pin" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "$relative_path: mise.toml must pin exact Node x.y.z; found '${node_pin:-none}'"
        failed=1
    fi

    if project_audit_mise_tracked "$project_dir"; then
        :
    else
        case "$?" in
            1)
                log_error "$relative_path: mise.toml exists but is untracked"
                ;;
            2)
                log_error "$relative_path: not in a git repo; mise.toml is local-only"
                ;;
        esac
        failed=1
    fi

    if [[ "$failed" -eq 0 ]]; then
        log_skip "$relative_path: Node $node_pin via tracked mise.toml ($package_manager)"
    fi

    return "$failed"
}

project_audit() {
    local developer_dir="${DEV_DIR:-$HOME/developer}"
    local package_json command_name failed=0 checked=0

    log_section "Project Runtime Audit"

    if [[ ! -d "$developer_dir" ]]; then
        log_error "$developer_dir missing"
        exit 1
    fi

    for command_name in jq git mise; do
        if ! command -v "$command_name" >/dev/null 2>&1; then
            log_error "$command_name not found"
            exit 1
        fi
    done

    while IFS= read -r package_json; do
        if [[ -n "$(project_audit_package_manager "$package_json")" ]]; then
            checked=$((checked + 1))
            project_audit_check_project "$developer_dir" "$package_json" || failed=1
        fi
    done < <(project_audit_package_json_files "$developer_dir")

    if [[ "$checked" -eq 0 ]]; then
        log_warn "No packageManager projects found under $developer_dir"
    elif [[ "$failed" -eq 0 ]]; then
        log_skip "Checked $checked packageManager projects"
    else
        log_error "Project runtime ownership drift found"
        exit 1
    fi
}
