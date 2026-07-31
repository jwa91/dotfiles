# ----------------------------------------
# File: completions.zsh
# Description: ZSH completion initialization and custom completions
# ----------------------------------------

if [[ -d "$HOME/.zfunc" ]]; then
    fpath=("$HOME/.zfunc" $fpath)
fi

# Initialize completion system: trust the dump if it was written in the last
# 24h, otherwise rebuild it (which also covers the missing-dump case).
#
# The glob qualifier has to run in an array assignment. Inside [[ ]] zsh does
# no filename generation, so the previous `[[ -f ~/.zcompdump(#qN.mh+24) ]]`
# was testing a literal filename, was always false, and left `compinit -C` as
# the only branch ever taken.
[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"
_zcompdump="$ZSH_CACHE_DIR/zcompdump"

autoload -Uz compinit
_zcompdump_fresh=($_zcompdump(Nmh-24))
if (( $#_zcompdump_fresh )); then
    compinit -C -d "$_zcompdump"
else
    compinit -d "$_zcompdump"
fi
unset _zcompdump _zcompdump_fresh

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
