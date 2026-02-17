# ----------------------------------------
# File: .zshrc
# Description: Main ZSH configuration file
# ----------------------------------------

# Load machine-specific secrets (if exists)
[[ -f "$ZSH_DIR/secrets.zsh" ]] && source "$ZSH_DIR/secrets.zsh"

# Load ZSH completions
source "$ZSH_DIR/completions.zsh"

# Load ZSH options
source "$ZSH_DIR/options.zsh"

# Load aliases
source "$ZSH_DIR/aliases.zsh"

# Load functions
source "$ZSH_DIR/functions.zsh"

# Load plugins
source "$ZSH_DIR/plugins.zsh"

# Load prompt configuration
source "$ZSH_DIR/prompt.zsh"
