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

# In zsh, lowercase `path` is tied to PATH. Guard noninteractive probes from
# accidentally clobbering command lookup with snippets like `for path in ...`.
dotfiles_harden_path() {
    if [[ ! -o interactive && "${DOTFILES_HARDEN_ZSH_PATH:-1}" == "1" ]]; then
        typeset -gr path
    fi
}

dotfiles_prepend_path
