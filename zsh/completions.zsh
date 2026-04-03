# ----------------------------------------
# File: completions.zsh
# Description: ZSH completion initialization and custom completions
# ----------------------------------------

# Initialize completion system (rebuild dump once per day, use cache otherwise)
autoload -Uz compinit
if [[ -f ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
# Add other tool-specific completions here

# ----------------------------------------
# Custom Completions
# ----------------------------------------

# Completion function for 'cdd'
_cdd() {
    if [[ -n "$DEV_DIR" && -d "$DEV_DIR" ]]; then
         _path_files -W "$DEV_DIR" -/
    fi
}

compdef _cdd cdd

# Completion function for 'ccbot'
_ccbot() {
    local -a actions=('start:Start a Claude Code session' 'stop:Stop a session' 'list:List running sessions')
    if (( CURRENT == 2 )); then
        _describe 'action' actions
    elif (( CURRENT == 3 )); then
        case "${words[2]}" in
            start)
                # Known projects + service dirs
                local -a names=('dotfiles' 'vault' 'vps')
                if [[ -d "$DEV_DIR/vps/services" ]]; then
                    names+=(${(@f)"$(ls -1 "$DEV_DIR/vps/services" 2>/dev/null | grep -v '^\.')"})
                fi
                _describe 'project' names
                ;;
            stop)
                if tmux list-sessions &>/dev/null; then
                    local -a sessions=('all:Stop all cc-* sessions')
                    sessions+=(${(@f)"$(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep '^cc-' | sed 's/^cc-//')"})
                    _describe 'session' sessions
                fi
                ;;
        esac
    fi
}

compdef _ccbot ccbot

# --- End Custom Completions ---