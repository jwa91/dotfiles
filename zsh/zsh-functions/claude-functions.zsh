# ----------------------------------------
# File: claude-functions.zsh
# Description: Claude Code workflow functions (worktrees + tmux)
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

# --------------------------------------------------
# Function: cw
# Description: Starts Claude Code in a dedicated git worktree inside a tmux
#              window. Creates a new branch and worktree from the current HEAD,
#              then launches claude with --dangerously-skip-permissions.
#              When claude exits you drop into a shell in the worktree.
#              Worktrees live in <repo>/.worktrees/ (globally gitignored).
#
#              If a tmux window for the same task already exists, switches to it.
#              Without arguments, opens an interactive picker of existing worktrees
#              or creates a new timestamped session.
#
# Usage: cw [-d] [task description]
# Flags:
#   -d    Start detached (claude runs in background, you stay where you are)
# Examples:
#   cw fix auth bug        -> branch claude/fix-auth-bug
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

    local slug worktree_dir="${repo_root}/.worktrees"

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
        # Sanitize: lowercase, spaces to hyphens, strip invalid chars, trim leading/trailing hyphens
        slug=$(echo "$*" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | sed 's/^-*//;s/-*$//')
    fi

    # Validate slug is not empty after sanitization
    if [[ -z "$slug" ]]; then
        echo "cw: could not create a valid name from '$*'" >&2
        echo "    use letters, numbers, or hyphens (e.g. cw fix-auth-bug)" >&2
        return 1
    fi

    local branch="claude/$slug"
    local worktree_path="${worktree_dir}/${slug}"
    local session_name="cw_${slug}"

    # Validate branch name with git before doing anything
    if ! git check-ref-format --allow-onelevel "refs/heads/$branch" 2>/dev/null; then
        echo "cw: '$branch' is not a valid git branch name" >&2
        echo "    try a simpler description (e.g. cw fix-auth-bug)" >&2
        return 1
    fi

    # If tmux session already exists, switch/attach to it
    if _cw_tmux_alive "$session_name"; then
        if [[ $detached -eq 1 ]]; then
            echo "cw: already running detached -> $session_name"
            return 0
        elif [[ -n "$TMUX" ]]; then
            echo "cw: switching to session ${session_name}"
            tmux switch-client -t "$session_name"
            return 0
        else
            echo "cw: attaching to session ${session_name}"
            tmux attach -t "$session_name"
            return 0
        fi
    fi

    # Create worktree if it doesn't exist yet
    if [[ -d "$worktree_path" ]]; then
        echo "cw: worktree exists -> .worktrees/${slug}"
    else
        mkdir -p "$worktree_dir"

        # Create branch from current HEAD (may already exist)
        if ! git -C "$repo_root" branch "$branch" HEAD 2>/dev/null; then
            # Branch exists — that's fine, worktree add will use it
            if ! git -C "$repo_root" rev-parse --verify "$branch" &>/dev/null; then
                echo "cw: failed to create branch '$branch'" >&2
                return 1
            fi
        fi

        if ! git -C "$repo_root" worktree add "$worktree_path" "$branch"; then
            echo "cw: failed to create worktree" >&2
            return 1
        fi

        echo "cw: branch   -> $branch"
        echo "cw: worktree -> .worktrees/${slug}"
    fi

    # Launch as a standalone tmux session (attachable from anywhere)
    local cmd="claude --dangerously-skip-permissions; echo ''; echo 'cw: claude exited — you are in the worktree'; exec zsh"

    if [[ -n "$TMUX" ]]; then
        # Inside tmux: create detached session, then switch to it
        tmux new-session -d -s "$session_name" -c "$worktree_path" "$cmd"
        if [[ $detached -eq 0 ]]; then
            tmux switch-client -t "$session_name"
        fi
    else
        if [[ $detached -eq 1 ]]; then
            tmux new-session -d -s "$session_name" -c "$worktree_path" "$cmd"
        else
            tmux new-session -s "$session_name" -c "$worktree_path" "$cmd"
        fi
    fi

    if [[ $detached -eq 1 ]]; then
        echo "cw: claude running detached -> $session_name"
        echo "    switch with: cw $slug"
    fi
}

# --------------------------------------------------
# Function: cw-ls
# Description: Lists Claude Code worktrees with status information.
#              Shows last commit time, merge status, dirty state, and tmux status.
# Usage: cw-ls
# --------------------------------------------------
function cw-ls() {
    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -z "$repo_root" ]]; then
        echo "cw-ls: not inside a git repository" >&2
        return 1
    fi

    local worktree_dir="${repo_root}/.worktrees"
    if [[ ! -d "$worktree_dir" ]] || [[ -z "$(ls -A "$worktree_dir" 2>/dev/null)" ]]; then
        echo "cw-ls: no claude worktrees found"
        return 0
    fi

    local main_branch
    main_branch=$(_cw_main_branch)
    [[ -z "$main_branch" ]] && main_branch="main"

    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local RED='\033[0;31m'
    local DIM='\033[2m'
    local NC='\033[0m'

    for d in "$worktree_dir"/*(N/); do
        local slug="${d:t}"
        local branch="claude/$slug"
        local session_name="cw_${slug}"

        # Last commit time
        local last_commit
        last_commit=$(git -C "$d" log -1 --format='%cr' 2>/dev/null)
        [[ -z "$last_commit" ]] && last_commit="no commits"

        # Uncommitted changes
        local dirty=""
        if [[ -n "$(git -C "$d" status --porcelain 2>/dev/null)" ]]; then
            dirty=" ${YELLOW}dirty${NC}"
        fi

        # Merged into main?
        local merge_status
        if git -C "$repo_root" merge-base --is-ancestor "$branch" "$main_branch" 2>/dev/null; then
            merge_status="${GREEN}merged${NC}"
        else
            merge_status="active"
        fi

        # tmux running?
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
# Function: cw-rm
# Description: Removes a Claude Code worktree, its tmux window, and branch.
#              Without arguments, lists worktrees to choose from.
# Usage: cw-rm <slug>
# Example: cw-rm fix-auth-bug
# --------------------------------------------------
function cw-rm() {
    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -z "$repo_root" ]]; then
        echo "cw-rm: not inside a git repository" >&2
        return 1
    fi

    if [[ -z "$1" ]]; then
        echo "usage: cw-rm <slug>"
        echo ""
        cw-ls
        return 1
    fi

    local slug="$1"
    local worktree_path="${repo_root}/.worktrees/${slug}"
    local branch="claude/$slug"
    local session_name="cw_${slug}"

    if [[ ! -d "$worktree_path" ]]; then
        echo "cw-rm: worktree not found: $worktree_path" >&2
        return 1
    fi

    # Kill tmux session if running
    tmux kill-session -t "$session_name" 2>/dev/null &&
        echo "cw-rm: killed tmux session"

    git -C "$repo_root" worktree remove "$worktree_path" --force &&
        echo "cw-rm: removed worktree"

    git -C "$repo_root" branch -D "$branch" 2>/dev/null &&
        echo "cw-rm: deleted branch $branch"
}

# --------------------------------------------------
# Function: cw-prune
# Description: Cleans up worktrees whose branches have been merged into main.
#              Removes the worktree directory, kills tmux windows, and deletes
#              the branch. Shows what would be pruned first and asks to confirm.
# Usage: cw-prune
# --------------------------------------------------
function cw-prune() {
    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -z "$repo_root" ]]; then
        echo "cw-prune: not inside a git repository" >&2
        return 1
    fi

    local worktree_dir="${repo_root}/.worktrees"
    if [[ ! -d "$worktree_dir" ]]; then
        echo "cw-prune: no worktrees directory"
        return 0
    fi

    local main_branch
    main_branch=$(_cw_main_branch)
    [[ -z "$main_branch" ]] && main_branch="main"

    # Collect merged worktrees
    local merged=()
    for d in "$worktree_dir"/*(N/); do
        local slug="${d:t}"
        local branch="claude/$slug"
        if git -C "$repo_root" merge-base --is-ancestor "$branch" "$main_branch" 2>/dev/null; then
            merged+=("$slug")
        fi
    done

    if [[ ${#merged[@]} -eq 0 ]]; then
        echo "cw-prune: nothing to prune (no branches merged into $main_branch)"
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
        cw-rm "$slug"
        ((count++))
    done

    echo ""
    echo "cw-prune: cleaned up $count worktree(s)"
}

# --------------------------------------------------
# Function: cw-send
# Description: Updates an Apple Note called "Claude Sessions" with active
#              tmux session info. Syncs via iCloud to your phone.
#              Pin the note as a widget for instant access to attach commands.
# Usage: cw-send
# --------------------------------------------------
CW_NOTES_FOLDER="Notes"
CW_NOTES_TITLE="Claude Sessions"

function cw-send() {
    # Collect all cw: windows across all tmux sessions
    local sessions=()
    local -A session_status

    while IFS= read -r name; do
        if [[ "$name" == cw_* ]]; then
            local slug="${name#cw_}"
            sessions+=("$slug")
            session_status[$slug]="running"
        fi
    done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null)

    # Also include worktrees without a running tmux window
    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -n "$repo_root" && -d "${repo_root}/.worktrees" ]]; then
        local repo_name="${repo_root:t}"
        for d in "${repo_root}/.worktrees"/*(N/); do
            local slug="${d:t}"
            if [[ -z "${session_status[$slug]}" ]]; then
                sessions+=("$slug")
                session_status[$slug]="stopped"
            fi
        done
    fi

    # Build HTML content for Apple Notes
    local html="<h1>Claude Sessions</h1>"
    html+="<p><i>Updated: $(date '+%Y-%m-%d %H:%M')</i></p>"

    if [[ ${#sessions[@]} -eq 0 ]]; then
        html+="<p>No active sessions.</p>"
    else
        for slug in "${sessions[@]}"; do
            local status="${session_status[$slug]}"
            local session_name="cw_${slug}"
            html+="<h2>${slug}</h2>"
            html+="<p>Status: <b>${status}</b></p>"
            html+="<pre>tmux attach -t ${session_name}</pre>"
        done
    fi

    # Update or create the note via AppleScript
    osascript <<EOF
tell application "Notes"
    set noteTitle to "${CW_NOTES_TITLE}"
    set noteBody to "${html}"
    set noteFound to false

    repeat with aNote in notes of default account
        if name of aNote is noteTitle then
            set body of aNote to noteBody
            set noteFound to true
            exit repeat
        end if
    end repeat

    if not noteFound then
        tell default account
            make new note with properties {name:noteTitle, body:noteBody}
        end tell
    end if
end tell
EOF

    if [[ $? -eq 0 ]]; then
        echo "cw-send: updated Apple Note '${CW_NOTES_TITLE}' (${#sessions[@]} session(s))"
    else
        echo "cw-send: failed to update Apple Note" >&2
        return 1
    fi
}
