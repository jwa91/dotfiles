# ----------------------------------------
# Core Dotfiles Directories
# ----------------------------------------
export DOTFILES_DIR="$HOME/dotfiles"
export CONFIG_DIR="$DOTFILES_DIR/config"
export GITCONFIG_DIR="$DOTFILES_DIR/git"
export ZSH_DIR="${ZSH_DIR:-$DOTFILES_DIR/zsh}"
export ZSH_PLUGINS_DIR="$HOME/.zsh_plugins"

# ----------------------------------------
# External Directories
# ----------------------------------------
export DEV_DIR="${DEV_DIR:-$HOME/Developer}"

# ----------------------------------------
# XDG Base Directories
# ----------------------------------------
# Let XDG_CONFIG_HOME default to ~/.config (standard location)
# Apps we control get explicit paths below instead of polluting dotfiles
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# ----------------------------------------
# Terminal-aware configurations
# ----------------------------------------
case "$TERM_PROGRAM" in
    vscode)
        export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship.toml"
        export EDITOR="cursor --wait"
        ;;
    ghostty)
        export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship.toml"
        export EDITOR="fresh"
        ;;
    tmux)
        # tmux overrides TERM_PROGRAM; check OUTER_TERM set by tmux.conf
        _outer=$(tmux show-environment -g OUTER_TERM 2>/dev/null | sed 's/.*=//')
        if [[ "$_outer" == "ghostty" ]]; then
            export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship.toml"
            export EDITOR="fresh"
        else
            export STARSHIP_CONFIG="$CONFIG_DIR/starship-mobile.toml"
            export EDITOR="micro"
        fi
        unset _outer
        ;;
    *)
        export STARSHIP_CONFIG="$CONFIG_DIR/starship-mobile.toml"
        export EDITOR="micro"
        ;;
esac

# ----------------------------------------
# Machine-specific paths
# ----------------------------------------
export VAULT_PATH="$HOME/Library/Mobile Documents/com~apple~CloudDocs/notes"

# ----------------------------------------
# PATH modifications
# Define tool-specific homes/paths BEFORE modifying PATH array
export BUN_INSTALL="$HOME/.bun"
export PNPM_HOME="$HOME/Library/pnpm"

# ----------------------------------------
# PATH modifications
# Using Zsh 'path' array for cleaner management and duplicate prevention
# ----------------------------------------
typeset -U -x path
path=(
    "$HOME/.local/bin" 
    /opt/homebrew/opt/node/bin
    /opt/homebrew/bin
    /opt/homebrew/sbin
    /usr/local/bin
    "$HOME/.npm-global/bin"
    "$BUN_INSTALL/bin"
    "$HOME/.antigravity/antigravity/bin"
    /Applications/Obsidian.app/Contents/MacOS
    $path
)
if [[ -d "$PNPM_HOME" && "${path[(i)$PNPM_HOME]}" -gt "${#path}" ]]; then
    path=("$PNPM_HOME" $path)
fi

# Vite+ bin (https://viteplus.dev)
[[ -f "$HOME/.vite-plus/env" ]] && . "$HOME/.vite-plus/env"
