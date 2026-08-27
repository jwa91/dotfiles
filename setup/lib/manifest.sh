#!/usr/bin/env bash

MANAGED_LINKS=(
    "$HOME/.gitconfig|$GIT_DIR/config|always"
    "$HOME/.config/git/commit_template.txt|$GIT_DIR/commit_template.txt|always"
    "$HOME/.config/git/ignore|$GIT_DIR/ignore|always"
    "$HOME/.zshrc|$ZSH_DIR/.zshrc|always"
    "$HOME/.zshenv|$ZSH_DIR/.zshenv|always"
    "$HOME/.zprofile|$ZSH_DIR/.zprofile|always"
    "$HOME/.config/ghostty|$CONFIG_DIR/ghostty|always"
    "$HOME/.config/openlogi|$CONFIG_DIR/openlogi|always"
    "$HOME/.config/starship.toml|$CONFIG_DIR/starship.toml|always"
    "$HOME/.claude/settings.json|$CONFIG_DIR/claude-code/settings.json|always"
    "$HOME/.config/cheat/conf.yml|$CONFIG_DIR/cheat/conf.yml|always"
    "$HOME/.config/cheat/cheatsheets/personal|$CONFIG_DIR/cheat/cheatsheets|always"
    "$HOME/.config/eza|$CONFIG_DIR/eza|always"
    "$HOME/.config/broot/conf.hjson|$CONFIG_DIR/broot/conf.hjson|always"
    "$HOME/.config/broot/verbs.hjson|$CONFIG_DIR/broot/verbs.hjson|always"
    "$HOME/.config/broot/skins|$CONFIG_DIR/broot/skins|always"
    "$HOME/.config/hunk/config.toml|$CONFIG_DIR/hunk/config.toml|always"
    "$HOME/.config/atuin/config.toml|$CONFIG_DIR/atuin/config.toml|always"
    "$HOME/.config/mise/config.toml|$CONFIG_DIR/mise/config.toml|always"
    "$HOME/.config/ty/ty.toml|$CONFIG_DIR/ty/ty.toml|always"
    "$HOME/.config/ruff/pyproject.toml|$CONFIG_DIR/ruff/pyproject.toml|always"
    "$HOME/.config/duti/defaults.duti|$CONFIG_DIR/duti/defaults.duti|always"
    "$HOME/.config/herdr/config.toml|$CONFIG_DIR/herdr/config.toml|always"
    "$HOME/.gnupg/gpg-agent.conf|$CONFIG_DIR/gnupg/gpg-agent.conf|always"
    "$HOME/.tmux.conf|$CONFIG_DIR/tmux/tmux.conf|always"
    "$HOME/.config/zed/settings.json|$CONFIG_DIR/zed/settings.json|zed"
    "$HOME/Library/Application Support/Cursor/User/settings.json|$CONFIG_DIR/cursor/settings.json|cursor"
    "$HOME/Library/Application Support/Cursor/User/keybindings.json|$CONFIG_DIR/cursor/keybindings.json|cursor"
    "$HOME/.cursor/mcp.json|$DOTFILES_LOCAL_CONFIG_DIR/cursor/mcp.json|cursor"
)

LOCAL_CONFIG_FILES=(
    "$HOME/.gitconfig.local|$GIT_DIR/config.local.example|always"
    "$DOTFILES_LOCAL_CONFIG_DIR/cursor/mcp.json|$CONFIG_DIR/cursor/mcp.example.json|cursor"
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

is_cursor_installed() {
    if command -v cursor >/dev/null 2>&1; then
        return 0
    fi

    [[ -d "/Applications/Cursor.app" || -d "$HOME/Applications/Cursor.app" ]]
}

is_zed_installed() {
    if command -v zed >/dev/null 2>&1; then
        return 0
    fi

    [[ -d "/Applications/Zed.app" || -d "$HOME/Applications/Zed.app" ]]
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
        zed)
            is_zed_installed
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
