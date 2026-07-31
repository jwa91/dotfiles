# ----------------------------------------
# File: plugins.zsh
# Description: ZLE plugins and shell integrations that bind widgets.
#
# Sourced last by .zshrc. Within this file the order is: widget-defining
# integrations first, then autosuggestions, then syntax highlighting.
# zsh-syntax-highlighting must stay last — below zsh 5.9 it wraps the widgets
# that exist when it is sourced, so anything bound after it is unhighlighted.
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

# Load fzf integration (binds ^T, ^R, alt-c)
if command -v fzf &> /dev/null; then
    source <(fzf --zsh)
fi

# Load zoxide (smart cd with frecency tracking)
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# Load atuin (shell history search and sync).
# Must stay after fzf: both bind ^R, and atuin is meant to win it.
if command -v atuin &> /dev/null; then
    eval "$(atuin init zsh)"
fi

# Load 1Password shell plugins (op plugin init <cli> populates this file)
_source_if_readable "$HOME/.config/op/plugins.sh" "1Password shell plugins" quiet

# Load autosuggestions
_source_if_readable "$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" "zsh-autosuggestions"

# Keep interactive comments readable in themes where black is the background.
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[comment]='fg=245'

# Load syntax highlighting — keep last, see header.
_source_if_readable "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" "zsh-syntax-highlighting"

unfunction _source_if_readable
