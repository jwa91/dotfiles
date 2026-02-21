# ----------------------------------------
# File: completions.zsh
# Description: ZSH completion initialization and custom completions
# ----------------------------------------

# Initialize completion system
autoload -Uz compinit
compinit

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

# Completion function for 'tproject'
_tproject() {
    local -a aliases
    aliases=(dots zsh vault)
    if [[ -n "$DEV_DIR" && -d "$DEV_DIR" ]]; then
        _alternative \
            "aliases:project alias:(${aliases[*]})" \
            "projects:DEV_DIR project:_path_files -W '$DEV_DIR' -/"
    else
        _describe 'project alias' aliases
    fi
}

compdef _tproject tproject

# --- End Custom Completions ---