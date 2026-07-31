# ----------------------------------------
# File: path.zsh
# Description: Canonical zsh PATH ordering
# ----------------------------------------

dotfiles_prepend_path() {
    typeset -U -x path
    path=(
        "$HOME/.local/bin"
        /Applications/OrbStack.app/Contents/MacOS/xbin
        /opt/homebrew/bin
        /opt/homebrew/sbin
        /usr/local/bin
        $path
    )
}

# In zsh, lowercase `path` is tied to PATH, so a snippet like `for path in ...`
# silently replaces command lookup. Making `path` read-only turns that into an
# immediate error instead.
#
# Off by default. The same syntax is also the canonical way to set PATH in zsh
# — dotfiles_prepend_path above uses it — so hardening rejects correct scripts
# and agent snippets far more often than it catches the accidental case, and it
# cannot tell the two apart. The accidental case is also self-limiting: the
# clobbered PATH dies with the one-shot shell that caused it and never reaches
# the parent.
#
# Opt in while diagnosing a suspected clobber:
#   DOTFILES_HARDEN_ZSH_PATH=1 zsh -c '...'
dotfiles_harden_path() {
    if [[ ! -o interactive && "${DOTFILES_HARDEN_ZSH_PATH:-0}" == "1" ]]; then
        typeset -gr path
    fi
}

dotfiles_prepend_path
