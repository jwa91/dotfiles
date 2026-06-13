# ----------------------------------------
# File: completions.zsh
# Description: ZSH completion initialization and custom completions
# ----------------------------------------

if [[ -d "$HOME/.zfunc" ]]; then
    fpath=("$HOME/.zfunc" $fpath)
fi

# Initialize completion system (rebuild dump once per day, use cache otherwise)
autoload -Uz compinit
if [[ -f ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

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

# --- End Custom Completions ---
