# ----------------------------------------
# File: plugins.zsh
# Description: ZSH plugin loading
# ----------------------------------------

# ----------------------------------------
# Usage:
# This file loads all ZSH plugins.
# These plugins are loaded by .zshrc.
# ----------------------------------------

# Codex gets a plain shell; ZLE plugins also need a real terminal.
if [[ -n "${CODEX_SHELL:-}" || "${__CFBundleIdentifier:-}" == "com.openai.codex" || ! -o interactive || ! -t 0 || ! -t 1 ]]; then
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

_zsh_plugins_dir="${ZSH_PLUGINS_DIR:-$HOME/.zsh_plugins}"

# Load autosuggestions
_source_if_readable "$_zsh_plugins_dir/zsh-autosuggestions/zsh-autosuggestions.zsh" "zsh-autosuggestions"

# Load syntax highlighting
_source_if_readable "$_zsh_plugins_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" "zsh-syntax-highlighting"

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
unset _zsh_plugins_dir
