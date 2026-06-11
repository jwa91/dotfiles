# ----------------------------------------
# Brewfile — the default install channel for ALL host software.
# Install with: brew bundle --file=~/dotfiles/Brewfile
#
# The one rule: everything installs from this file. Exceptions are
# enumerated, never derived:
#   - setup/lib/brew.sh installs the fast-moving agent CLIs (claude code,
#     codex, amp) via their first-party installers — same-day updates.
#   - setup/manual-installs.txt is the short human checklist (App Store,
#     interactive installers, on-demand toolchains).
# Identical on both machines: a tool exists on both or on neither.
#
# House rules:
# - GUI casks are bootstrap-only installs: the apps self-update through
#   their own channels; `brew upgrade` skips them (auto_updates).
#   Never pass --greedy.
# - Before adding a formula, run `brew deps <formula>` — nothing that
#   drags python/node/ruby onto the host (that mistake cost us httpie).
# - Project runtimes never land here: uv (Python) and mise (node/pnpm/bun)
#   provision per-project only. Outside a project, node and python
#   intentionally don't resolve. setup/doctor.sh verifies.
# ----------------------------------------

# Taps
tap "1password/tap"
tap "jwa91/tap"
tap "protonpass/tap"
tap "stalecontext/forgejo-cli-plus", "https://codeberg.org/stalecontext/homebrew-forgejo-cli-plus.git"

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
# 1Password is the current truth; Proton Pass is the delayed migration target.
brew "gnupg"
brew "pinentry-mac"
brew "protonpass/tap/pass-cli"
cask "1password-cli"

# Terminal visuals
cask "font-jetbrains-mono-nerd-font"
cask "ghostty"

# GUI apps (bootstrap-only: each self-updates via its own channel;
# codexbar and hiddenbar are the exceptions — brew upgrade updates them)
cask "claude"
cask "codexbar"
cask "cursor"
cask "google-chrome@dev"
cask "helium-browser"
cask "hiddenbar"
cask "obsidian"
cask "proton-pass"
cask "raycast"
cask "spotify"
cask "stats"
cask "telegram"
cask "whatsapp"
