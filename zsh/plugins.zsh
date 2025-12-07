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

# Load syntax highlighting (must be loaded before history-substring-search)
source $ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Load history substring search
source $ZSH_PLUGINS_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh

# Load fzf integration
if command -v fzf &> /dev/null; then
    source <(fzf --zsh)
fi