# ----------------------------------------
# File: claude-functions.zsh
# Description: Claude Code workflow functions (worktrees + tmux)
#              Delegates worktree + tmux creation to built-in flags
#              (claude -w <name> --tmux, added in Claude Code 2.1.50).
# Author: Jan Willem Altink
# ----------------------------------------

# Helper: detect the main branch for the current repo
_cw_main_branch() {
    local ref
    ref=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)
    echo "${ref##refs/remotes/origin/}"
}

# Helper: check if a tmux session named $1 exists
_cw_tmux_alive() {
    tmux has-session -t "$1" 2>/dev/null
}

# Helper: derive tmux session name matching built-in convention
# Built-in uses: ${basename(repoRoot)}_worktree-${name}
_cw_session_name() {
    local repo_root="$1" slug="$2"
    echo "${repo_root:t}_worktree-${slug}"
}

# --------------------------------------------------
# Function: cw
# Description: Starts Claude Code in a dedicated git worktree inside a tmux
#              session. Delegates worktree and tmux creation to the built-in
#              `claude -w <name> --tmux=classic` flags.
#
#              If a tmux session for the same task already exists, switches to it.
#              Without arguments, opens an interactive picker of existing worktrees
#              or creates a new timestamped session.
#
# Usage: cw [-d] [task description]
# Flags:
#   -d    Start detached (claude runs in background, you stay where you are)
# Examples:
#   cw fix auth bug        -> worktree fix-auth-bug
#   cw -d fix auth bug     -> same, but detached
#   cw                     -> pick existing or start new session
# --------------------------------------------------
function cw() {
    local detached=0
    if [[ "$1" == "-d" ]]; then
        detached=1
        shift
    fi

    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -z "$repo_root" ]]; then
        echo "cw: not inside a git repository" >&2
        return 1
    fi

    if ! command -v claude &>/dev/null; then
        echo "cw: claude CLI not found" >&2
        return 1
    fi

    local slug
    local worktree_dir="${repo_root}/.claude/worktrees"

    # No arguments: pick existing worktree or create new
    if [[ -z "$*" ]]; then
        local existing=()
        if [[ -d "$worktree_dir" ]]; then
            for d in "$worktree_dir"/*(N/); do
                existing+=("${d:t}")
            done
        fi

        if [[ ${#existing[@]} -gt 0 ]] && command -v fzf &>/dev/null; then
            slug=$(printf '%s\n' "${existing[@]}" "+ new session" | fzf --prompt="cw> " --height=~10)
            [[ -z "$slug" ]] && return 0
            if [[ "$slug" == "+ new session" ]]; then
                slug="session-$(date +%Y%m%d-%H%M%S)"
            fi
        elif [[ ${#existing[@]} -gt 0 ]]; then
            echo "Active worktrees:"
            printf '  %s\n' "${existing[@]}"
            echo ""
            echo "Reattach:  cw <name>"
            echo "New:       cw <task description>"
            return 0
        else
            slug="session-$(date +%Y%m%d-%H%M%S)"
        fi
    else
        slug=$(echo "$*" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | sed 's/^-*//;s/-*$//')
    fi

    if [[ -z "$slug" ]]; then
        echo "cw: could not create a valid name from '$*'" >&2
        echo "    use letters, numbers, or hyphens (e.g. cw fix-auth-bug)" >&2
        return 1
    fi

    local session_name
    session_name=$(_cw_session_name "$repo_root" "$slug")

    # If tmux session already exists, switch/attach to it
    if _cw_tmux_alive "$session_name"; then
        if [[ $detached -eq 1 ]]; then
            echo "cw: already running -> $session_name"
            return 0
        elif [[ -n "$TMUX" ]]; then
            tmux switch-client -t "$session_name"
            return 0
        else
            tmux attach -t "$session_name"
            return 0
        fi
    fi

    # Delegate to claude CLI for worktree + tmux creation
    if [[ $detached -eq 1 ]]; then
        tmux new-session -d -s "$session_name" -c "$repo_root" \
            "claude -w ${(q)slug} --dangerously-skip-permissions"
        echo "cw: running detached -> $session_name"
        echo "    attach: cw $slug"
    else
        claude -w "$slug" --tmux=classic --dangerously-skip-permissions
    fi
}

# --------------------------------------------------
# Function: cwls
# Description: Lists Claude Code worktrees with status information.
#              Shows last commit time, merge status, dirty state, and tmux status.
# Usage: cwls
# --------------------------------------------------
function cwls() {
    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -z "$repo_root" ]]; then
        echo "cwls: not inside a git repository" >&2
        return 1
    fi

    local worktree_dir="${repo_root}/.claude/worktrees"
    if [[ ! -d "$worktree_dir" ]] || [[ -z "$(ls -A "$worktree_dir" 2>/dev/null)" ]]; then
        echo "cwls: no claude worktrees found"
        return 0
    fi

    local main_branch
    main_branch=$(_cw_main_branch)
    [[ -z "$main_branch" ]] && main_branch="main"

    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local DIM='\033[2m'
    local NC='\033[0m'

    for d in "$worktree_dir"/*(N/); do
        local slug="${d:t}"
        local session_name
        session_name=$(_cw_session_name "$repo_root" "$slug")

        local branch
        branch=$(git -C "$d" rev-parse --abbrev-ref HEAD 2>/dev/null)
        [[ -z "$branch" ]] && branch="?"

        local last_commit
        last_commit=$(git -C "$d" log -1 --format='%cr' 2>/dev/null)
        [[ -z "$last_commit" ]] && last_commit="no commits"

        local dirty=""
        if [[ -n "$(git -C "$d" status --porcelain 2>/dev/null)" ]]; then
            dirty=" ${YELLOW}dirty${NC}"
        fi

        local merge_status
        if git -C "$repo_root" merge-base --is-ancestor "$branch" "$main_branch" 2>/dev/null; then
            merge_status="${GREEN}merged${NC}"
        else
            merge_status="active"
        fi

        local tmux_status
        if _cw_tmux_alive "$session_name"; then
            tmux_status="${GREEN}tmux running${NC}"
        else
            tmux_status="${DIM}tmux: -${NC}"
        fi

        printf "  %-24s  %-20s  %-8b  %b  %b\n" \
            "$slug" "$last_commit" "$merge_status" "$tmux_status" "$dirty"
    done
}

# --------------------------------------------------
# Function: cwrm
# Description: Removes a Claude Code worktree, its tmux session, and branch.
#              Without arguments, lists worktrees to choose from.
# Usage: cwrm <slug>
# Example: cwrm fix-auth-bug
# --------------------------------------------------
function cwrm() {
    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -z "$repo_root" ]]; then
        echo "cwrm: not inside a git repository" >&2
        return 1
    fi

    if [[ -z "$1" ]]; then
        echo "usage: cwrm <slug>"
        echo ""
        cwls
        return 1
    fi

    local slug="$1"
    local worktree_path="${repo_root}/.claude/worktrees/${slug}"
    local session_name
    session_name=$(_cw_session_name "$repo_root" "$slug")

    if [[ ! -d "$worktree_path" ]]; then
        echo "cwrm: worktree not found: $slug" >&2
        return 1
    fi

    local branch
    branch=$(git -C "$worktree_path" rev-parse --abbrev-ref HEAD 2>/dev/null)

    tmux kill-session -t "$session_name" 2>/dev/null &&
        echo "cwrm: killed tmux session"

    git -C "$repo_root" worktree remove "$worktree_path" --force &&
        echo "cwrm: removed worktree"

    if [[ -n "$branch" && "$branch" != "HEAD" ]]; then
        git -C "$repo_root" branch -D "$branch" 2>/dev/null &&
            echo "cwrm: deleted branch $branch"
    fi
}

# --------------------------------------------------
# Function: cwprune
# Description: Cleans up worktrees whose branches have been merged into main.
#              Removes the worktree directory, kills tmux sessions, and deletes
#              the branch. Shows what would be pruned first and asks to confirm.
# Usage: cwprune
# --------------------------------------------------
function cwprune() {
    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -z "$repo_root" ]]; then
        echo "cwprune: not inside a git repository" >&2
        return 1
    fi

    local worktree_dir="${repo_root}/.claude/worktrees"
    if [[ ! -d "$worktree_dir" ]]; then
        echo "cwprune: no worktrees directory"
        return 0
    fi

    local main_branch
    main_branch=$(_cw_main_branch)
    [[ -z "$main_branch" ]] && main_branch="main"

    local merged=()
    for d in "$worktree_dir"/*(N/); do
        local slug="${d:t}"
        local branch
        branch=$(git -C "$d" rev-parse --abbrev-ref HEAD 2>/dev/null)
        if [[ -n "$branch" ]] && git -C "$repo_root" merge-base --is-ancestor "$branch" "$main_branch" 2>/dev/null; then
            merged+=("$slug")
        fi
    done

    if [[ ${#merged[@]} -eq 0 ]]; then
        echo "cwprune: nothing to prune (no branches merged into $main_branch)"
        return 0
    fi

    echo "The following worktrees are merged into $main_branch:"
    printf '  %s\n' "${merged[@]}"
    echo ""

    read -q "confirm?Prune all? [y/N] " || { echo ""; return 0; }
    echo ""

    local count=0
    for slug in "${merged[@]}"; do
        echo ""
        echo "Pruning $slug..."
        cwrm "$slug"
        ((count++))
    done

    echo ""
    echo "cwprune: cleaned up $count worktree(s)"
}
