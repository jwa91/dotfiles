# ----------------------------------------
# File: plugins.zsh
# Description: ZSH plugin loading
# ----------------------------------------

# ----------------------------------------
# Usage:
# This file loads all ZSH plugins.
# These plugins are loaded by .zshrc.
# ----------------------------------------

# Load autosuggestions
source $ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh

# Load syntax highlighting
source $ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

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
if [[ -f "$HOME/.config/op/plugins.sh" ]]; then
    source "$HOME/.config/op/plugins.sh"
fi
