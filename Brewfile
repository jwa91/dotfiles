# ----------------------------------------
# Brewfile — base macOS package/bootstrap layer.
# Install with: brew bundle --file=~/dotfiles/Brewfile
#
# The rule: every tool has one owner. Homebrew 6+ owns base packages and
# casks without their own updater, but not project runtime versions or
# self-updating app freshness. See docs/system.md for the full model.
#
# House rules:
# - Prefer homebrew/core; every third-party tap declares `trusted: true`.
# - Bootstrap runs brew bundle with HOMEBREW_BUNDLE_NO_UPGRADE=1.
# - App casks with `auto_updates true` are bootstrap installers. The app's own
#   updater owns freshness afterwards. Casks without that metadata stay
#   Homebrew-owned.
# - Before adding a formula, run `brew deps <formula>` — nothing that
#   drags python/node/ruby onto the host (that mistake cost us httpie).
# - Project runtimes never land here: uv owns Python, mise owns runtime
#   versions, and packageManager + Corepack own pnpm versions.
# ----------------------------------------

# Taps
tap "1password/tap", trusted: true
tap "cloudflare/cloudflare", trusted: true
tap "jwa91/tap", trusted: true
tap "protonpass/tap", trusted: true
tap "stalecontext/forgejo-cli-plus", "https://codeberg.org/stalecontext/homebrew-forgejo-cli-plus.git", trusted: true
tap "steipete/tap", trusted: true
tap "terraform-linters/tap", trusted: true

# Personal tap binaries — installed in bootstrap order:
# a Homebrew Cask via goreleaser's homebrew_casks: block).
cask "jwa-harden"
cask "agentskills"
cask "prehandover"
cask "terraform-linters/tap/tflint"

# Shell & terminal core
brew "git"
brew "git-lfs"
brew "tmux"
brew "starship"
brew "fzf"
brew "eza"
brew "broot"
brew "hunk"
brew "duti"
brew "zoxide"
brew "atuin"
brew "micro"
brew "just"
brew "tree"
brew "watch"
brew "cheat"
brew "tlrc"
brew "coreutils"
brew "xh"
brew "mosh"
brew "hcloud"
brew "forgejo-cli-plus"
brew "cloudflare/cloudflare/cf-terraforming"
brew "opentofu"
brew "pass"
brew "rsync"
brew "uv"
brew "mise"
brew "ripgrep"
brew "jq"
brew "shellcheck"
brew "prek"
brew "gitleaks"
brew "gnupg"
brew "pinentry-mac"
brew "protonpass/tap/pass-cli"

cask "1password-cli"
cask "font-jetbrains-mono-nerd-font"
cask "ghostty"
cask "orbstack"
cask "steipete/tap/codexbar"
cask "hiddenbar"

# GUI apps (bootstrap casks with auto_updates true; app owns freshness)
cask "claude"
cask "codex-app"
cask "cursor"
cask "google-chrome@dev"
cask "helium-browser"
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
cask "zed"
