# ----------------------------------------
# File: plugins.zsh
# Description: ZSH plugin loading
# ----------------------------------------

# ----------------------------------------
# Usage:
# This file loads all ZSH plugins.
# These plugins are loaded by .zshrc.
# ----------------------------------------

# ZLE plugins need an interactive shell attached to a real terminal.
if [[ ! -o interactive || ! -t 0 || ! -t 1 ]]; then
    return 0
fi

_source_if_readable() {
    local file="$1"
    local label="${2:-$1}"
    local mode="${3:-warn}"

    if [[ -r "$file" ]]; then
        source "$file"
    elif [[ "$mode" != "quiet" ]]; then
        print -u2 "dotfiles: skipping $label (missing: $file)"
    fi
}

# Load autosuggestions
_source_if_readable "$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" "zsh-autosuggestions"

# Keep interactive comments readable in themes where black is the background.
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[comment]='fg=245'

# Load syntax highlighting
_source_if_readable "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" "zsh-syntax-highlighting"

# Load fzf integration
if command -v fzf &> /dev/null; then
    source <(fzf --zsh)
fi

# Load zoxide (smart cd with frecency tracking)
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# Load atuin (shell history search and sync)
if command -v atuin &> /dev/null; then
    eval "$(atuin init zsh)"
fi

# Load 1Password shell plugins (op plugin init <cli> populates this file)
_source_if_readable "$HOME/.config/op/plugins.sh" "1Password shell plugins" quiet

unfunction _source_if_readable
