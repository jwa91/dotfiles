# ----------------------------------------
# File: path.zsh
# Description: Canonical zsh PATH ordering
# ----------------------------------------

dotfiles_prepend_path() {
    typeset -U -x path
    path=(
        "$HOME/.local/bin"
        "$HOME/.cargo/bin"
        "$HOME/.local/share/go/bin"
        /usr/local/go/bin
        /Applications/OrbStack.app/Contents/MacOS/xbin
        /opt/homebrew/bin
        /opt/homebrew/sbin
        /usr/local/bin
        $path
    )
}

dotfiles_prepend_path
