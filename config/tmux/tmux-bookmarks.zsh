# ----------------------------------------
# File: tmux-bookmarks.zsh
# Description: Tmux session bookmarks and interactive picker.
#              Uses variables from .zshenv — no hardcoded paths.
# ----------------------------------------

# --------------------------------------------------
# Bookmark definitions
# --------------------------------------------------
typeset -gA TMUX_BOOKMARKS_DIR TMUX_BOOKMARKS_CMD

TMUX_BOOKMARKS_DIR[vault]="$VAULT_PATH"
TMUX_BOOKMARKS_DIR[vps]="$DEV_DIR/vps"
TMUX_BOOKMARKS_CMD[vps]="ssh edge"

# --------------------------------------------------
# Function: tpick
# Description: Interactive tmux session picker showing live sessions and
#              launchable bookmarks. Usable from desktop and mobile (via mosh).
#              Live sessions attach directly; bookmarks create then attach.
# Usage: tpick [--mobile]
# Flags:
#   --mobile    Sets CW_MOBILE=1 on the target session via tmux set-environment
# --------------------------------------------------

# Helper: format seconds into human-readable age
_tpick_age() {
    local seconds=$1
    if (( seconds < 60 )); then
        echo "${seconds}s ago"
    elif (( seconds < 3600 )); then
        echo "$(( seconds / 60 ))m ago"
    elif (( seconds < 86400 )); then
        echo "$(( seconds / 3600 ))h ago"
    else
        echo "$(( seconds / 86400 ))d ago"
    fi
}

# Helper: abbreviate a path for display (~/first/.../last)
_tpick_path() {
    local p="${1/#$HOME/~}"
    if (( ${#p} <= 35 )); then
        echo "$p"
        return
    fi
    local parts=("${(@s:/:)p}")
    echo "${parts[1]}/${parts[2]}/.../${parts[-1]}"
}

function tpick() {
    local mobile=0
    if [[ "$1" == "--mobile" ]]; then
        mobile=1
        shift
    fi

    if ! command -v fzf &>/dev/null; then
        echo "tpick: fzf required but not found" >&2
        return 1
    fi

    local lines=()
    local -A line_type
    local now=$(date +%s)

    # Collect live tmux sessions
    if tmux list-sessions &>/dev/null; then
        while IFS=$'\t' read -r name activity sess_path sess_attached; do
            local age=$(( now - activity ))
            local age_str=$(_tpick_age $age)
            local path_str=$(_tpick_path "$sess_path")
            local attached_str=""
            if (( sess_attached > 0 )); then
                attached_str="  \033[2mattached\033[0m"
            fi
            lines+=("$(printf '%-22s \033[32m●\033[0m  %-30s  %s' "$name" "$path_str" "$age_str")${attached_str}")
            line_type[$name]="live"
        done < <(tmux list-sessions -F '#{session_name}	#{session_activity}	#{session_path}	#{session_attached}' 2>/dev/null)
    fi

    # Collect bookmarks not currently running
    local bookmark_lines=()
    if (( ${#TMUX_BOOKMARKS_DIR} > 0 )); then
        for name in "${(@k)TMUX_BOOKMARKS_DIR}"; do
            if [[ -n "${line_type[$name]}" ]]; then
                continue
            fi
            local path_str=$(_tpick_path "${TMUX_BOOKMARKS_DIR[$name]}")
            bookmark_lines+=("$(printf '%-22s \033[2m○\033[0m  %s' "$name" "$path_str")")
            line_type[$name]="bookmark"
        done
    fi

    # Nothing to show
    if [[ ${#lines[@]} -eq 0 && ${#bookmark_lines[@]} -eq 0 ]]; then
        echo "tpick: no sessions or bookmarks found"
        echo "  Add bookmarks in: \$CONFIG_DIR/tmux/tmux-bookmarks.zsh"
        return 0
    fi

    # Add separator and bookmark lines
    if [[ ${#lines[@]} -gt 0 && ${#bookmark_lines[@]} -gt 0 ]]; then
        lines+=("─────────────────────────────────────────")
    fi
    lines+=("${bookmark_lines[@]}")

    local fzf_out
    fzf_out=$(printf '%s\n' "${lines[@]}" | fzf --ansi --prompt="tmux> " --height=~15 --reverse \
        --expect=ctrl-x --header='ctrl-x: kill session')
    [[ -z "$fzf_out" ]] && return 0

    local key selection
    key=$(head -1 <<< "$fzf_out")
    selection=$(tail -1 <<< "$fzf_out")
    [[ -z "$selection" ]] && return 0
    [[ "$selection" == ─* ]] && return 0

    # Extract session/bookmark name (first field)
    local target
    target=$(echo "$selection" | awk '{print $1}')
    local type="${line_type[$target]}"

    # Handle ctrl-x: kill session and re-invoke picker
    if [[ "$key" == "ctrl-x" ]]; then
        if [[ "$type" == "live" ]]; then
            tmux kill-session -t "$target" 2>/dev/null
        fi
        if (( mobile )); then
            tpick --mobile
        else
            tpick
        fi
        return $?
    fi

    if [[ "$type" == "live" ]]; then
        if [[ $mobile -eq 1 ]]; then
            tmux set-environment -t "$target" CW_MOBILE 1
        fi
        if [[ -n "$TMUX" ]]; then
            tmux switch-client -t "$target"
        else
            tmux attach -t "$target"
        fi
    elif [[ "$type" == "bookmark" ]]; then
        local dir="${TMUX_BOOKMARKS_DIR[$target]}"
        local cmd="${TMUX_BOOKMARKS_CMD[$target]}"

        if [[ -n "$cmd" ]]; then
            tmux new-session -d -s "$target" -c "$dir" "$cmd"
        else
            tmux new-session -d -s "$target" -c "$dir"
        fi

        if [[ $mobile -eq 1 ]]; then
            tmux set-environment -t "$target" CW_MOBILE 1
        fi

        if [[ -n "$TMUX" ]]; then
            tmux switch-client -t "$target"
        else
            tmux attach -t "$target"
        fi
    fi
}
