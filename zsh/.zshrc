# ----------------------------------------
# File: .zshrc
# Description: Main ZSH configuration file
# ----------------------------------------

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

export GPG_TTY="$(tty)"

if [[ -r "$HOME/.config/broot/launcher/bash/br" ]]; then
    source "$HOME/.config/broot/launcher/bash/br"
fi

# Activate mise. Global Go/Rust baselines live in config/mise/config.toml;
# Node/pnpm/Bun stay project-scoped unless a project declares them.
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
fi
