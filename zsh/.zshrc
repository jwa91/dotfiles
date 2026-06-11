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

if [[ -d "${BUN_INSTALL:-$HOME/.bun}" ]]; then
    export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
    path=("$BUN_INSTALL/bin" $path)

    if [[ -r "$BUN_INSTALL/_bun" ]]; then
        source "$BUN_INSTALL/_bun"
    fi
fi
