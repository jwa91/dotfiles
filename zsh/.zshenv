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
if [[ -z "${DEV_DIR:-}" ]]; then
    if [[ -d "$HOME/developer" ]]; then
        export DEV_DIR="$HOME/developer"
    else
        export DEV_DIR="$HOME/Developer"
    fi
else
    export DEV_DIR
fi

# Prefer a local agentskills checkout when present on this machine.
_agentskills_local="$DEV_DIR/agentskills"
if [[ -n "${AGENTSKILLS_REPO_PATH:-}" && ! -d "$AGENTSKILLS_REPO_PATH/skills" && -d "$_agentskills_local/skills" ]]; then
    export AGENTSKILLS_REPO_PATH="$_agentskills_local"
elif [[ -z "${AGENTSKILLS_REPO_PATH:-}" && -d "$_agentskills_local/skills" ]]; then
    export AGENTSKILLS_REPO_PATH="$_agentskills_local"
fi
unset _agentskills_local

# ----------------------------------------
# XDG Base Directories
# ----------------------------------------
# Let XDG_CONFIG_HOME default to ~/.config (standard location)
# Apps we control get explicit paths below instead of polluting dotfiles
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# ----------------------------------------
# Terminal-aware configurations
# ----------------------------------------
# Detection order:
#   1. $TERM — survives SSH, set by the terminal emulator (e.g. xterm-ghostty)
#   2. $TERM_PROGRAM — local-only, used for vscode and tmux detection
#   3. OUTER_TERM — tmux env var from tmux.conf to recover the launching terminal
_set_desktop_terminal() {
    export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship.toml"
    export EDITOR="fresh"
}
_set_mobile_terminal() {
    export STARSHIP_CONFIG="$CONFIG_DIR/starship-mobile.toml"
    export EDITOR="micro"
}

if [[ "$TERM" == "xterm-ghostty" ]]; then
    # Ghostty — works locally and over SSH
    _set_desktop_terminal
elif [[ "$TERM_PROGRAM" == "vscode" ]]; then
    export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship.toml"
    export EDITOR="cursor --wait"
elif [[ "$TERM_PROGRAM" == "tmux" ]]; then
    # tmux overrides both TERM and TERM_PROGRAM; check OUTER_TERM set by tmux.conf
    _outer=$(tmux show-environment -g OUTER_TERM 2>/dev/null | sed 's/.*=//')
    if [[ "$_outer" == "ghostty" ]]; then
        _set_desktop_terminal
    else
        _set_mobile_terminal
    fi
    unset _outer
else
    _set_mobile_terminal
fi

unset -f _set_desktop_terminal _set_mobile_terminal

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
    "$HOME/go/bin"
    "$HOME/.npm-global/bin"
    "$BUN_INSTALL/bin"
    "$HOME/.antigravity/antigravity/bin"
    $path
)
if [[ -d "$PNPM_HOME" && "${path[(i)$PNPM_HOME]}" -gt "${#path}" ]]; then
    path=("$PNPM_HOME" $path)
fi

# Vite+ bin (https://viteplus.dev)
[[ -f "$HOME/.vite-plus/env" ]] && . "$HOME/.vite-plus/env"
