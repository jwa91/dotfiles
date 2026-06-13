# ----------------------------------------
# Brewfile — base macOS package/bootstrap layer.
# Install with: brew bundle --file=~/dotfiles/Brewfile
#
# The rule: every tool has one owner. Homebrew owns base packages and
# bootstrap casks, but not project runtime versions or self-updating app
# freshness. See docs/system.md for the full model.
#
# House rules:
# - Bootstrap runs brew bundle with HOMEBREW_BUNDLE_NO_UPGRADE=1.
# - GUI casks are allowed only as bootstrap installers. The app's own
#   updater owns freshness afterwards. Interactive shells set
#   HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1 for this reason.
# - Before adding a formula, run `brew deps <formula>` — nothing that
#   drags python/node/ruby onto the host (that mistake cost us httpie).
# - Project runtimes never land here: uv owns Python projects, and mise
#   owns Go, Rust, Node, pnpm, and Bun versions.
# ----------------------------------------

# Taps
tap "1password/tap"
tap "jwa91/tap"
tap "protonpass/tap"
tap "stalecontext/forgejo-cli-plus", "https://codeberg.org/stalecontext/homebrew-forgejo-cli-plus.git"
tap "steipete/tap"

# Personal tap binaries — installed in bootstrap order:
# hardening wrapper, skill distribution, harness alignment.
# (ADR 0008 in jwa91/homebrew-tap: every Go CLI in the family ships as
# a Homebrew Cask via goreleaser's homebrew_casks: block).
cask "jwa-harden"
cask "agentskills"
cask "prehandover"

# Shell & terminal core
brew "git"
brew "git-lfs"
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
brew "coreutils"

# Network & infra CLI
brew "xh"
brew "mosh"
brew "hcloud"
brew "forgejo-cli-plus"

# Project-runtime managers (the runtimes themselves stay project-scoped)
brew "uv"
brew "mise"

# Dotfiles and script maintenance (prek hooks need these on every machine)
brew "ripgrep"
brew "jq"
brew "shellcheck"
brew "prek"
brew "gitleaks"

# Auth, signing, and password-manager CLI
# 1Password is the current truth; Proton Pass is installed but not part of
# the current secrets/SSH plan.
brew "gnupg"
brew "pinentry-mac"
brew "protonpass/tap/pass-cli"
cask "1password-cli"

# Terminal visuals
cask "font-jetbrains-mono-nerd-font"
cask "ghostty"

# Containers
cask "orbstack"

# GUI apps (bootstrap-only: each self-updates via its own channel)
cask "claude"
cask "codex-app"
cask "steipete/tap/codexbar"
cask "cursor"
cask "google-chrome@dev"
cask "helium-browser"
cask "hiddenbar"
cask "obsidian"
cask "proton-drive"
cask "proton-mail"
cask "proton-pass"
cask "protonvpn"
cask "raycast"
cask "spotify"
cask "stats"
cask "telegram"
cask "whatsapp"
