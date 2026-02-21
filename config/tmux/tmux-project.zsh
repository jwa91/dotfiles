# ----------------------------------------
# File: tmux-project.zsh
# Description: Scripted tmux project layout.
#              Creates a 3-pane session: shell | fresh | git overview
# ----------------------------------------

# --------------------------------------------------
# Function: _tproject_resolve
# Description: Resolves a project name to a directory path.
#              Checks: DEV_DIR subdirectory, known aliases, absolute path.
# --------------------------------------------------
_tproject_resolve() {
    local input="$1"

    # No argument = current directory
    if [[ -z "$input" ]]; then
        pwd
        return 0
    fi

    # Known aliases (same locations as edots/cddots etc.)
    case "$input" in
        dots|dotfiles) echo "$DOTFILES_DIR"; return 0 ;;
        zsh)           echo "$ZSH_DIR"; return 0 ;;
        vault)         echo "$VAULT_PATH"; return 0 ;;
    esac

    # DEV_DIR subdirectory
    if [[ -n "$DEV_DIR" && -d "$DEV_DIR/$input" ]]; then
        echo "$DEV_DIR/$input"
        return 0
    fi

    # Absolute or relative path
    if [[ -d "$input" ]]; then
        (cd "$input" && pwd)
        return 0
    fi

    return 1
}

# --------------------------------------------------
# Function: _tproject_git_graph
# Description: Live-updating git graph for tproject's git pane.
#              Uses watch -x to bypass sh -c (avoids format string quoting issues).
# --------------------------------------------------
_tproject_git_graph() {
    watch -c -x -n 5 -- git -c color.ui=always log --all --graph --abbrev-commit \
        --format=format:'%C(bold blue)%h%C(reset) %C(auto)%d%C(reset) %<(30,trunc)%s'
}

# --------------------------------------------------
# Function: tproject
# Description: Creates or attaches to a tmux project session with a
#              3-pane layout: shell, Fresh editor, and git overview.
#              Resolves names like cdd does: DEV_DIR subdirs, known aliases.
#
# Usage: tproject [name]
#   name    Project name, alias, or path (defaults to current directory)
#
# Examples:
#   tproject dotfiles    -> ~/dotfiles
#   tproject aw          -> ~/Developer/aw
#   tproject             -> current directory
#
# Layout:
#   ┌───────┬──────────────┬───────┐
#   │       │              │       │
#   │ shell │    fresh     │  git  │
#   │ ~25%  │    ~50%      │ ~25%  │
#   │       │              │       │
#   │       │              │       │
#   └───────┴──────────────┴───────┘
# --------------------------------------------------
function tproject() {
    local dir
    dir=$(_tproject_resolve "$1") || {
        echo "tproject: unknown project: $1" >&2
        echo "  Use a DEV_DIR subdirectory, alias (dots/zsh/vault), or path" >&2
        return 1
    }

    # Session name from directory basename
    local name="${dir:t}"

    # If session exists, just attach/switch
    if tmux has-session -t "$name" 2>/dev/null; then
        if [[ -n "$TMUX" ]]; then
            tmux switch-client -t "$name"
        else
            tmux attach -t "$name"
        fi
        return 0
    fi

    # Fresh command
    # TODO: use `fresh -a` for session restore (file explorer, cursor positions)
    local fresh_cmd="fresh"
    [[ -f "$dir/TODO.md" ]] && fresh_cmd="fresh TODO.md"

    # Pane 1: shell — pass terminal dimensions so detached session splits at correct size
    tmux new-session -d -s "$name" -c "$dir" -x "$(tput cols)" -y "$(tput lines)"

    # Pane 2: fresh editor (75% of window → shell keeps 25%)
    tmux split-window -h -t "${name}:.1" -c "$dir" -l 75% "$fresh_cmd"

    # Pane 3: git overview (33% of pane 2's 75% → ~25% of window)
    tmux split-window -h -t "${name}:.2" -c "$dir" -l 33%

    # Start git graph via helper function (send-keys avoids quoting issues)
    if git -C "$dir" rev-parse --is-inside-work-tree &>/dev/null; then
        tmux send-keys -t "${name}:.3" _tproject_git_graph Enter
    fi

    # Focus shell pane
    tmux select-pane -t "${name}:.1"

    # TODO: auto-maximize terminal window (raycast deeplink unreliable)

    # Attach or switch
    if [[ -n "$TMUX" ]]; then
        tmux switch-client -t "$name"
    else
        tmux attach -t "$name"
    fi
}
