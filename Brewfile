# ----------------------------------------
# Shared Brewfile — installed on every machine.
# Install with: brew bundle --file=~/dotfiles/Brewfile
# Machine extras live in Brewfile.<profile>; bootstrap applies both based on
# the profile name in ~/.config/dotfiles-local/profile.
#
# Boundary:
# - Homebrew owns system/shell/bootstrap tools.
# - App-layer installs stay outside Brewfile.
# - uv and mise are standalone ~/.local/bin tools (bootstrap installs them).
# - AI tools (claude desktop, claude code, codex, codexbar) install via their
#   official channels for faster updates — see setup/manual-installs.txt.
# - Project runtimes stay project-owned, never global:
#   Python -> uv
#   TypeScript/JavaScript -> mise -> node/pnpm/bun (per-project pins only)
#   Go -> official go.dev installer (go.mod toolchain directive pins versions)
#   Rust -> rustup/cargo
# ----------------------------------------

# Taps
tap "1password/tap"
tap "jwa91/tap"
tap "protonpass/tap"

# Personal tap binaries — installed in bootstrap order:
# hardening wrapper, skill distribution, harness alignment.
# (ADR 0008 in jwa91/homebrew-tap: every Go CLI in the family ships as
# a Homebrew Cask via goreleaser's homebrew_casks: block).
cask "jwa-harden"
cask "agentskills"
cask "prehandover"

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
brew "tree"
brew "watch"
brew "cheat"

# Dotfiles and script maintenance (prek hooks need these on every machine)
brew "ripgrep"
brew "jq"
brew "shellcheck"
brew "prek"
brew "gitleaks"

# Auth, signing, and password-manager CLI
# 1Password is the current truth; Proton Pass is the delayed migration target.
brew "gnupg"
brew "pinentry-mac"
brew "protonpass/tap/pass-cli"
cask "1password-cli"

# Terminal visuals
cask "font-jetbrains-mono-nerd-font"
cask "ghostty"
