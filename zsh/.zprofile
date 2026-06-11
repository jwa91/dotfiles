# ----------------------------------------
# File: .zprofile
# Description: Login-shell environment. Runs after .zshenv, before .zshrc.
# ----------------------------------------

# Homebrew environment (PATH, MANPATH, INFOPATH, HOMEBREW_PREFIX, …).
# Note: `brew shellenv` PREPENDS /opt/homebrew/{bin,sbin} to PATH, which
# would otherwise shadow ~/.local/bin (uv, uvx, user-managed runtimes).
eval "$(/opt/homebrew/bin/brew shellenv zsh)"

# Re-assert user-managed bins at the very front, after Homebrew has had its
# say. `typeset -U` (declared in .zshenv) keeps the array unique, so listing
# ~/.local/bin again simply moves it back to the front — no duplicates.
path=("$HOME/.local/bin" $path)
