#!/usr/bin/env bash
# Initialize Zsh plugins, directories, and generated completions.

# Move pre-XDG zsh state to its new home. Idempotent: each entry moves only
# when the old path still exists and the new one does not, so a half-migrated
# machine converges and an already-migrated one is a no-op. Never removes
# anything — if both paths exist, the old one is left alone and reported.
migrate_zsh_state() {
    local spec old new
    local migrations=(
        "$HOME/.zsh_plugins|$ZSH_PLUGINS_DIR"
        "$HOME/.zsh_history|$ZSH_STATE_DIR/history"
        "$HOME/.zcompdump|$ZSH_CACHE_DIR/zcompdump"
    )

    for spec in "${migrations[@]}"; do
        old="${spec%%|*}"
        new="${spec#*|}"

        # A shell started before this change still exports the old locations,
        # and those overrides are honoured. Nothing to migrate in that case.
        [[ "$old" == "$new" ]] && continue
        [[ -e "$old" ]] || continue

        if [[ -e "$new" ]]; then
            log_warn "Both $old and $new exist; leaving $old in place"
            continue
        fi

        log_action "Migrate $old -> $new"
        run_cmd mkdir -p "$(dirname "$new")"
        run_cmd mv "$old" "$new"
    done
}

setup_zsh_environment() {
    log_section "Zsh Environment"

    migrate_zsh_state

    ensure_dir "$ZSH_PLUGINS_DIR"
    ensure_dir "$ZSH_STATE_DIR"
    ensure_dir "$ZSH_CACHE_DIR"
    # Not relocated: rustup and uv write completions here themselves.
    ensure_dir "$HOME/.zfunc"
    ensure_dir "$HOME/developer"
    ensure_dir "$HOME/.local/bin"

    local plugins=(
        "zsh-autosuggestions:https://github.com/zsh-users/zsh-autosuggestions"
        "zsh-syntax-highlighting:https://github.com/zsh-users/zsh-syntax-highlighting"
    )

    local plugin name url path
    for plugin in "${plugins[@]}"; do
        name="${plugin%%:*}"
        url="${plugin#*:}"
        path="$ZSH_PLUGINS_DIR/$name"

        if [[ -d "$path" ]]; then
            if $UPDATE_PLUGINS; then
                log_action "Update $name"
                run_cmd git -C "$path" pull --ff-only
            else
                log_skip "$path"
            fi
        else
            log_action "Clone $name"
            run_cmd git clone --depth 1 "$url" "$path"
        fi
    done

    if command -v pass-cli >/dev/null 2>&1; then
        log_action "Generate pass-cli zsh completion"
        if $DRY_RUN; then
            echo -e "${YELLOW}WOULD:${NC} pass-cli completions zsh > $HOME/.zfunc/_pass-cli"
        else
            pass-cli completions zsh > "$HOME/.zfunc/_pass-cli"
        fi
    else
        log_warn "pass-cli not found; skipping Proton Pass completion"
    fi

    if command -v herdr >/dev/null 2>&1; then
        log_action "Generate Herdr zsh completion"
        if $DRY_RUN; then
            echo -e "${YELLOW}WOULD:${NC} herdr completion zsh > $HOME/.zfunc/_herdr"
        else
            herdr completion zsh > "$HOME/.zfunc/_herdr"
        fi
    else
        log_warn "herdr not found; skipping Herdr completion"
    fi
}
