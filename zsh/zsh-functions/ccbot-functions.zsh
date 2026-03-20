# ----------------------------------------
# File: ccbot-functions.zsh
# Description: Manage Claude Code sessions with Telegram channels via tmux.
#              Each session runs in a detached tmux session (cc-<name>),
#              fetches its Telegram bot token from 1Password, and connects
#              to a dedicated Telegram bot for remote interaction.
# Dependencies: tmux, op (1Password CLI), claude
# ----------------------------------------

# --------------------------------------------------
# 1Password item naming convention:
#   op://Personal/CCBOT_<NAME>/password
#   e.g. op://Personal/CCBOT_DOTFILES/password
# --------------------------------------------------

# --------------------------------------------------
# Function: _ccbot_dir
# Description: Resolves a project name to its directory path.
#              Known names get explicit mappings; anything else
#              falls back to $DEV_DIR/vps/services/<name>.
# Usage: _ccbot_dir <name>
# --------------------------------------------------
_ccbot_dir() {
    case "$1" in
        dotfiles) echo "$DOTFILES_DIR" ;;
        notes)    echo "$VAULT_PATH" ;;
        vps)      echo "$DEV_DIR/vps" ;;
        *)        echo "$DEV_DIR/vps/services/$1" ;;
    esac
}

# --------------------------------------------------
# Function: ccbot
# Description: Manage Claude Code + Telegram channel sessions in tmux.
# Usage:
#   ccbot start <name>       Start a session for <name>
#   ccbot stop <name>        Stop a session
#   ccbot stop all           Stop all cc-* sessions
#   ccbot list               List running cc-* sessions
# --------------------------------------------------
function ccbot() {
    local action="$1"
    local name="$2"

    case "$action" in
        start)
            if [[ -z "$name" ]]; then
                echo "Usage: ccbot start <name>" >&2
                return 1
            fi

            local session="cc-$name"
            local dir=$(_ccbot_dir "$name")

            if [[ ! -d "$dir" ]]; then
                echo "ccbot: directory does not exist: $dir" >&2
                return 1
            fi

            if tmux has-session -t "$session" 2>/dev/null; then
                echo "ccbot: session '$session' already running" >&2
                return 1
            fi

            local op_item="CCBOT_${(U)name}"
            local token
            if ! token=$(op read "op://Personal/$op_item/password" 2>/dev/null); then
                echo "ccbot: failed to read token from op://Personal/$op_item/password" >&2
                echo "  Create it: op item create --category=Password --title='$op_item' --vault=Personal" >&2
                return 1
            fi

            tmux new-session -d -s "$session" -c "$dir" \
                -x "$(tput cols)" -y "$(tput lines)"
            tmux send-keys -t "$session" \
                "TELEGRAM_BOT_TOKEN='$token' claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official" Enter

            echo "ccbot: started $session in $dir"
            ;;

        stop)
            if [[ -z "$name" ]]; then
                echo "Usage: ccbot stop <name|all>" >&2
                return 1
            fi

            if [[ "$name" == "all" ]]; then
                local sessions
                sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep '^cc-')
                if [[ -z "$sessions" ]]; then
                    echo "ccbot: no sessions running"
                    return 0
                fi
                echo "$sessions" | while read -r s; do
                    tmux kill-session -t "$s"
                    echo "ccbot: stopped $s"
                done
            else
                local session="cc-$name"
                if tmux kill-session -t "$session" 2>/dev/null; then
                    echo "ccbot: stopped $session"
                else
                    echo "ccbot: session '$session' not found" >&2
                    return 1
                fi
            fi
            ;;

        list)
            local sessions
            sessions=$(tmux list-sessions -F '#{session_name}  #{session_path}  (#{session_activity})' 2>/dev/null | grep '^cc-')
            if [[ -z "$sessions" ]]; then
                echo "ccbot: no sessions running"
            else
                echo "$sessions"
            fi
            ;;

        *)
            echo "Usage: ccbot <start|stop|list> [name]" >&2
            return 1
            ;;
    esac
}
