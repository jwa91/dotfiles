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

# Activate mise. Global toolchain baselines live in config/mise/config.toml.
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"

    _dotfiles_after_mise_hook() {
        # Keep dotfiles policy shims ahead of mise's activated tool bins. The
        # shims still resolve project runtimes through mise; they just enforce
        # ownership.
        dotfiles_prepend_path
    }

    add-zsh-hook -d precmd _dotfiles_after_mise_hook 2>/dev/null
    add-zsh-hook -d chpwd _dotfiles_after_mise_hook 2>/dev/null
    add-zsh-hook precmd _dotfiles_after_mise_hook
    add-zsh-hook chpwd _dotfiles_after_mise_hook
    _dotfiles_after_mise_hook
fi
