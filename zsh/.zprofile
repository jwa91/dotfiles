# ----------------------------------------
# File: .zprofile
# Description: Login-shell environment. Runs after .zshenv, before .zshrc.
# ----------------------------------------

# Homebrew environment (PATH, MANPATH, INFOPATH, HOMEBREW_PREFIX, …).
# Note: `brew shellenv` PREPENDS /opt/homebrew/{bin,sbin} to PATH, which
# would otherwise shadow ~/.local/bin (uv, uvx, user-managed runtimes).
eval "$(/opt/homebrew/bin/brew shellenv zsh)"

# Re-assert the canonical path order after macOS path_helper and Homebrew have
# had their say.
source "$ZSH_DIR/path.zsh"
dotfiles_harden_path
