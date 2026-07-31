# ----------------------------------------
# File: .zshrc
# Description: Interactive shell configuration.
#
# Load order is deliberate:
#   options      shell behaviour, before anything reads it
#   functions    fpath and autoload declarations, before compinit
#   completions  compinit, needs the final fpath
#   aliases
#   broot, mise  integrations that do not need ZLE
#   prompt       starship
#   plugins      ZLE plugins; syntax highlighting stays last
#
# On zsh 5.9 zsh-syntax-highlighting uses the zle-line-pre-redraw hook and
# wraps no widgets, so this order is not load-bearing here. It matters below
# zsh 5.9, where the plugin falls back to wrapping widgets that exist at
# source time.
# ----------------------------------------

source "$ZSH_DIR/options.zsh"
source "$ZSH_DIR/functions.zsh"
source "$ZSH_DIR/completions.zsh"
source "$ZSH_DIR/aliases.zsh"

export GPG_TTY="$(tty)"

if [[ -r "$HOME/.config/broot/launcher/bash/br" ]]; then
    source "$HOME/.config/broot/launcher/bash/br"
fi

# Activate mise. Global toolchain baselines live in config/mise/config.toml.
# Deliberately not tty-gated: `just doctor` verifies shim precedence through
# `zsh -ic`, which has no tty, and that check depends on the precmd hook below.
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

source "$ZSH_DIR/prompt.zsh"
source "$ZSH_DIR/plugins.zsh"
