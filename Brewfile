# ----------------------------------------
# Canonical Brewfile
# Install with: brew bundle --file=~/dotfiles/Brewfile
#
# Boundary:
# - Homebrew owns system/shell/bootstrap tools.
# - App-layer installs stay outside Brewfile.
# - uv and mise are standalone ~/.local/bin tools.
# - Project runtimes stay project-owned:
#   Python -> uv
#   TypeScript/JavaScript -> mise -> node/pnpm/bun
#   Go -> official go toolchain
#   Rust -> rustup/cargo
# ----------------------------------------

# Taps
tap "protonpass/tap"

# Shell & terminal core
brew "git"
brew "tmux"
brew "starship"
brew "fzf"
brew "eza"
brew "broot"
brew "zoxide"
brew "atuin"
brew "micro"
brew "just"

# Dotfiles and script maintenance
brew "ripgrep"
brew "jq"
brew "shellcheck"

# Auth, signing, and password-manager CLI
brew "gnupg"
brew "pinentry-mac"
brew "protonpass/tap/pass-cli"

# Terminal visuals
cask "font-jetbrains-mono-nerd-font"
cask "ghostty"
