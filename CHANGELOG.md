# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project follows Semantic Versioning.

## [Unreleased]
### Changed
- Trimmed system docs to current ownership rules.
- `just toolchains` installs every tool declared in the repo mise config.
- Doctor treats project-declared mise installs under `~/developer` as owned.
- Dotfiles shims route `node`, `npm`, `npx`, and `pnpm` through project-owned Node.
- JS global install guards moved from zsh functions into the dotfiles shims.
- Doctor requires ambient JS commands to resolve to dotfiles shims.
- Doctor allows Bun's package cache while warning on official installer state.
- Doctor's Brewfile check skips Homebrew auto-update noise.

### Removed
- Tracked Codex runtime config; Codex config stays machine-local.

## [3.0.1] - 2026-06-13
### Breaking Changes
- Reworked bootstrap around one-owner runtime management: Homebrew is the base
  package layer, while `uv` owns Python and `mise` owns Go, Rust, Node, pnpm,
  and Bun.
- Changed the canonical local layout to `~/dotfiles`, `~/developer`,
  `~/.local/bin`, `~/.zsh_plugins`, and `~/.config/dotfiles-local`; the
  previous `~/Developer` fallback is gone.
- Removed Homebrew ownership of project runtimes and global developer tools
  that now belong to project config, `mise`, `uv`, or standalone installers.
- Removed managed VS Code, GitHub CLI, tmux bookmark, `ccbot`, Next.js route,
  and repo-local agent-skill surfaces from the default configuration.

### Added
- Targetable bootstrap flow with modular setup libraries, `setup/doctor.sh`,
  and `just` tasks for bootstrap, checks, links, toolchains, help, zsh setup,
  and manual setup.
- Managed symlink and machine-local config seeding, including Cursor-aware
  link conditions and migration of already-managed directories into symlinks.
- Baseline `mise` config plus zsh owner guards for Python, JavaScript, Go, and
  Rust mutation commands.
- Portable helpers in `bin/` for markdown clipping, command help, skill
  scaffolding, Proton Pass agent access, filename case conversion, and
  Starship runtime metadata.
- Broot skins and verbs, eza theme overrides, dotfiles cheat sheets, Proton
  Pass shell helpers, and Codex/Cursor/OrbStack-oriented local config.

### Changed
- Homebrew convergence is now presence-only with
  `HOMEBREW_BUNDLE_NO_UPGRADE=1`, and cleanup remains a report instead of a
  deletion step.
- Fast-moving agent CLIs are installed outside Homebrew.
- zsh startup now sources shared POSIX environment, socket-gates Proton
  Pass/1Password SSH agents, reasserts PATH after `brew shellenv`, and
  activates `mise` from `.zshrc`.
- Cursor, Claude Code, Git, Atuin, Ghostty, Broot, Starship, and cheat
  configuration were trimmed around durable defaults and the new ownership
  model.

### Fixed
- Bootstrap now fails early when required repository paths or local config
  seeds are missing.
- Doctor checks now detect unmanaged links, missing local config, missing mise
  baselines, direct runtime installs, global npm/Go/Cargo residue, and Docker
  Desktop leftovers.
- Pre-push main guard now lives under `hooks/` and continues to require a
  `v*` tag on `HEAD` plus a matching changelog entry.

### Removed
- Repo-local agent skills and Claude skill symlink mirrors.
- Old Git setup helpers, SSH allowed signers, stale tmux and cheat surfaces,
  and zsh function files that are no longer part of the managed shell surface.
- Brewfile entries that violated the runtime ownership model or are no longer
  part of the base stack.

## [2.18.1] - 2026-05-29
### Added
- Proton Pass CLI via Homebrew for password-manager workflows.

### Removed
- Removed the Ghostty/ZLE shift-select experiment entirely. The terminal now
  keeps normal Ghostty selection behavior, and zsh no longer loads custom
  Shift+Arrow widgets.
- Retired the terminal editor integration that wrote project-local workspace
  state. Ghostty shells and editor helpers now use `micro`.

## [2.18.0] - 2026-05-28
### Added
- Ghostty keybindings and ZLE helpers for Shift+Arrow text selection, with
  region deletion and a `SHIFT_SELECT=false` escape hatch.
- Ghostty shell integration settings for SSH environment and terminfo setup.

### Changed
- Starship initialization is now guarded so shell reloads do not re-wrap ZLE
  widgets used by vi mode and shift-select.

## [2.17.0] - 2026-05-26
### Added
- Machine-local Git signing include via `~/.gitconfig.local`, with an example
  config for the 1Password SSH signer and local allowed signers.
- `gnupg`, `pinentry-mac`, and `hcloud` to the Brewfile for release signing and
  VPS/Hetzner workflows.
- 1Password shell plugin loading from `~/.config/op/plugins.sh`.

### Changed
- Global Git author email now uses `code@janwillemaltink.com`.
- Replaced Yazi dotfile/bootstrap wiring with Broot config and shell launcher
  support.

## [2.16.0] - 2026-05-23
### Added
- **1Password SSH agent integration** in `zsh/.zshenv`: `SSH_AUTH_SOCK` routes
  through `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`
  when present, so `ssh`/`ssh-add` use keys stored in 1Password instead of
  unencrypted private keys on disk.
- `WORKSPACES_DIR`, `SCHEMAS_DIR`, `PREFERENCES_DIR` exports in `.zshenv` for
  canonical project locations.
- `goreleaser`, `forgejo-cli-plus`, and `odin` added to Brewfile.
  `forgejo-cli-plus` comes from the `stalecontext/forgejo-cli-plus` Codeberg
  tap.

### Changed
- Personal tap Casks in Brewfile now follow the intended bootstrap order:
  `jwa-harden`, `agentskills`, `prehandover`, `jwa-tobrew`.
- `mkskill` now uses the Brew-installed `agentskills` CLI by default
  instead of assuming a local `~/Developer/agentskills` source checkout.
- `DEV_DIR` now defaults to `~/developer` when present (fallback: `~/Developer`),
  and bootstrap creates the same resolved path for consistent local repo layout.
- Python helper sourcing now follows `DEV_DIR` (no hardcoded `~/Developer` path).
- Added `docs/cli-boundary-and-layout.md` to codify what stays in dotfiles vs
  what belongs in portable Go CLIs, plus the local `DEV_DIR` repo layout.
- Local repo layout normalized under `~/developer`: `agentskills` moved to
  `~/developer/agentskills` and `prehandover` to `~/developer/prehandover`;
  `mkskill` and docs now point to the new canonical paths.
- tmux `vps` bookmark SSH target switched from `hetzner` to `edge`.
- Repo `.gitignore` now ignores `drafts/06-as-is-machine-analysis.md`.
- **Pre-push main guard rewritten** to use HEAD + branch state instead of
  reading refs from stdin. prek's `language: script` pre-push hooks do not
  forward stdin, args, or `PRE_COMMIT_*` env vars, so the previous version
  silently passed every push. The new guard checks `git symbolic-ref HEAD` and
  `git tag --points-at HEAD`; bypass with `SKIP=require-tag-and-changelog git push`.

### Removed
- **Codex config sync and drift detection.** `config/codex/`,
  `setup/codex/sync.{sh,py}`, `setup/hooks/codex-config-drift.sh`, the
  `codex-config-drift` prek hook, and the bootstrap codex-sync step are gone.
  Codex rewrites `~/.codex/config.toml` at runtime; keeping a dotfiles base in
  sync churned more than it saved. Live config is now untracked.
- `antigravity` cask removed from Brewfile.

## [2.15.1] - 2026-05-13
### Changed
- **`agentskills` and `prehandover` switched from `brew` to `cask`** in Brewfile. Both completed their `brews:` → `homebrew_casks:` migration in their own repos (agentskills v0.1.1, prehandover v0.1.1) — now signed + notarized like the rest of the `jwa-*` family. Tracks tap v0.4.1.

## [2.15.0] - 2026-05-13
### Added
- **`prehandover` formula** to Brewfile (already shipped at v0.1.0 from its own repo).
- **`jwa-harden` cask** to Brewfile (jwa91/tap — new repo). Wraps a command with `op run` against the nearest `.env.template`; replaces the long-standing "(when that exists)" placeholder in `jwa-tobrew doctor` and various skills.
- **`jwa-tobrew` cask** to Brewfile (previously `brew`, now `cask` because the binary moved to its own repo and ships as a Homebrew Cask via goreleaser's `homebrew_casks:` block per ADR 0008 in homebrew-tap).

### Changed
- **Personal-tap Brewfile section** restructured: formulae (`agentskills`, `prehandover`) above, casks (`jwa-harden`, `jwa-tobrew`) below. The bootstrap-only comment that gated `jwa-tobrew` install is gone — the publisher is now its own repo with its own release pipeline (jwa91/jwa-tobrew).
- **All `jwa-*` casks ship codesigned + notarized** with Developer ID Application (TEAMID U3ST8HC98U, the same identity used by `trnscrb`). Releases happen locally via `make release VERSION=…`; CI workflows are `workflow_dispatch`-only in both repos until a `.p8` App Store Connect API key is added to GH secrets. The fine-grained tap-writer PAT (op://Personal/GitHub Homebrew-tap writer/credential) is used only for the Cask commit; `GITHUB_TOKEN` for release-creation on the source repo comes from `gh auth token` at release time.

## [2.14.2] - 2026-05-11
### Added
- `go` to Brewfile (needed by an external project; Starship `[golang]` module and Go formatter integration already in place).
- Claude Code `skipAutoPermissionPrompt = true`.

### Changed
- Codex drift detection now treats `model_reasoning_effort` and `plan_mode_reasoning_effort` as runtime (machine-/project-local), not base. Removed `model_reasoning_effort` from `config/codex/config.toml` so reasoning effort is tuned per project, not unified at the dotfiles level.
- `setup/codex/sync.py` now exposes a `compose <base> <live>` command (and `split_runtime` returns three buckets: base / runtime keys / runtime sections) so runtime top-level keys are spliced back into the pre-header region instead of dumped between sections. `setup/codex/sync.sh` switched from `extract-runtime` to `compose`.

## [2.14.1] - 2026-05-10
### Added
- Claude Code voice mode (`voice.enabled = true`, `mode = "hold"`).

### Changed
- Cursor `git.openRepositoryInParentFolders` flipped from `never` to `always` so subfolder opens surface the parent repo.
- Cursor `biome.requireConfiguration = true` so Biome only activates in projects that declare a config.

### Fixed
- `codex-config-drift` hook now matches bare runtime tables (e.g. `[tui.model_availability_nux]`), not just nested subkeys. Previously the dotted prefix `tui.model_availability_nux.` only matched `[tui.model_availability_nux.foo]`, so the bare table Codex actually writes counted as drift and blocked commits.

### Removed
- Redundant `/Applications/Obsidian.app/Contents/MacOS` PATH entry in `.zshenv`. Obsidian 1.12.7 ships a dedicated `obsidian-cli` binary that the Homebrew cask now symlinks to `/opt/homebrew/bin/obsidian`, so the manual PATH entry (which previously pointed at the GUI binary and produced `FATAL: Unable to find helper app` errors via Electron's helper-app resolution) is no longer needed.
- Stale `Last Modified` header in `zsh/zsh-functions/general-functions.zsh` — git already tracks edit time, and sibling files in `zsh-functions/` don't carry one.

## [2.14.0] - 2026-05-06
### Added
- Codex config sync pattern: `setup/codex/sync.sh` writes `~/.codex/config.toml` from the dotfiles base while preserving machine-local sections that Codex rewrites at runtime.
- `codex-config-drift` prek hook (pre-commit stage): fails commits when `~/.codex/config.toml` diverges from the dotfiles base, ignoring runtime sections (`[projects.*]`, `[marketplaces.*]`, `[plugins.*]`, `[notice.*]`, `tui.model_availability_nux.*`). Bypass with `SKIP=codex-config-drift`.
- `marksman` markdown LSP in Brewfile.
- Claude Code `preferredNotifChannel = "ghostty"`.

### Changed
- Codex config no longer symlinked into dotfiles — Codex rewrites it at runtime, so the live file is a real file synced from a slim base. Trust marks, plugin enables, and marketplace cache stay out of the repo.
- Codex base: model bumped to `gpt-5.5`.
- `ccbot health` points to `$DEV_DIR/health` (was `~/Documents/health`).

### Fixed
- Removed `.sh` suffix alias that caused executable scripts to open in the editor instead of executing.

### Removed
- Cursor `alt+cmd+s` sidebar toggle keybinding.

## [2.13.0] - 2026-04-03
### Added
- Suffix aliases for `.swift`, `.tsx`, `.jsx`, `.css`, `.rs`, `.go`, `.env` (edit) and `.webp`, `.mov` (view).
- Bootstrap `--update` flag to pull latest zsh plugin versions via `git pull --ff-only`.
- Bootstrap now symlinks `~/.gitconfig` to `git/config` (previously required separate `git/setup.sh`).

### Changed
- `compinit` cached: full security check runs once per day, uses cached dump otherwise for faster shell startup.

## [2.12.2] - 2026-04-03
### Changed
- Moved `mcpServers` from shared `settings.json` to machine-local `~/.claude.json` — paths and API keys no longer leak across machines.
- Broadened Claude Code permissions to bypass mode with explicit tool allow list.
- Added `alwaysThinkingEnabled` to shared Claude Code settings.

### Added
- `health` project mapping in ccbot.

## [2.12.1] - 2026-04-03
### Fixed
- Guard Vite+ env sourcing in `.zshenv` to prevent errors on machines where Vite+ is not installed.

### Changed
- Terminal detection in `.zshenv` now checks `$TERM` for `xterm-ghostty` before `$TERM_PROGRAM`, fixing prompt and editor detection over SSH.

## [2.12.0] - 2026-03-21
### Added
- `ccbot` shell function — manages Claude Code sessions with Telegram channels via tmux. Tokens stored in 1Password, project directories resolved automatically (dotfiles, vault, VPS, and VPS services via wildcard fallback).
- Tab completion for `ccbot` (actions, project names, running sessions).
- Vite+ (`vp`) added to `install_standalone_tools` in bootstrap script.
- Vite+ env sourcing in `.zshenv`.
- Telegram and Discord plugins enabled in Claude Code settings.

### Fixed
- Claude Code MCP filesystem path corrected from `/Users/jw/projects` to `/Users/jw/Developer`.

## [2.11.0] - 2026-03-19
### Changed
- Brewfile: replaced keg-only `node@24` with mainline `node` formula to fix `libsimdjson.30.dylib` crash and ensure Homebrew keeps dependencies in sync on upgrades.

## [2.10.0] - 2026-03-13
### Added
- `biome` added to Brewfile as global fallback for IDE linting/formatting.

### Removed
- All `amp.*` settings from VS Code and Cursor configs — Amp VS Code plugin is deprecated.
- Hardcoded `biome.lsp.bin` path from Cursor config — extension auto-detects project-local or global binary.

## [2.9.0] - 2026-03-12
### Added
- Atuin shell history: Brewfile entry, config (`config/atuin/config.toml`), zsh plugin init, bootstrap symlink.
- Atuin cheat sheet entries (ctrl-r, up-arrow, stats, import).
- Zsh history options (`EXTENDED_HISTORY`, `HIST_IGNORE_ALL_DUPS`, `SHARE_HISTORY`, etc.) in `options.zsh`.

## [2.8.0] - 2026-03-11
### Added
- `..` alias for `cd ..`.
- `getmd` shell function — fetches clean markdown from a URL via defuddle.md API, copies to clipboard by default.
- Obsidian added to PATH in `.zprofile`.

### Changed
- Codex: model updated to `gpt-5.4`, root project trust level added.
- Claude Code: `code-review` plugin enabled, effort level set to `high`.
- Cursor: `alt+cmd+s` keybinding for unified sidebar toggle.

### Fixed
- `.zprofile` trailing newline.

## [2.7.0] - 2026-03-02
### Added
- `brewsync` alias — runs `brew bundle --cleanup` against the dotfiles Brewfile.

### Changed
- Replaced `pre-commit` with `prek` (Rust-based drop-in replacement) in Brewfile and README.

## [2.6.1] - 2026-02-28
### Changed
- `VAULT_PATH` updated to new Obsidian vault location (`notes`).

### Removed
- Amp VS Code settings (`amp.tryOpus`, `amp.guardedFiles.allowlist`) — plugin deprecated.

## [2.6.0] - 2026-02-27
### Added
- Brewfile: `yazi` terminal file manager, `zoxide` smart directory jumper.
- Yazi config (`config/yazi/yazi.toml`) with gruvbox-material theme and bootstrap symlinks for `theme.toml` and `init.lua`.
- Zoxide shell init in `plugins.zsh` with `z` and `zi` cheat sheet entries.

### Removed
- `tproject` tmux 3-pane layout function, completions, and cheat sheet entry.
- `cw`/`cwls`/`cwrm`/`cwprune` Claude Code worktree functions (`claude-functions.zsh`).
- `docker-desktop` brew cask (manual install preferred, documented in `manual-installs.txt`).

## [2.5.0] - 2026-02-27
### Added
- Suffix aliases for editor file types (md, json, yaml, toml, py, js, ts, etc.) — type a filename to open in `_eopen`.
- Suffix aliases for viewer file types (html, pdf, png, jpg, svg, gif, mp4, csv) — type a filename to open in default app.

### Removed
- `config/claude/` — Claude Desktop config dir (example template, developer_settings). App manages its own config at default location.
- `config/claude-code/commands/`, `agents/`, README, .gitignore — agent resources don't belong in dotfiles config. Only `settings.json` remains.
- `config/codex/instructions.md`, README, .gitignore — agent instruction file, not config. Only `config.toml` remains.
- Bootstrap symlinks for Claude Desktop (6 lines), claude-code commands/agents (2 lines), codex instructions.md (1 line).

### Changed
- Config boundary clarified: this repo only manages classic config files, not agent resources (skills, instructions, commands). Agent resources belong in a dedicated AI repo.

## [2.4.0] - 2026-02-26
### Added
- Brewfile: `ripgrep`, `coreutils`, `1password-cli`, `antigravity`, `google-chrome@dev`, `ngrok`, `stats`, `telegram`, `whatsapp`, `cleanmymac`, `helium-browser`, `codexbar`.
- Brewfile: taps for `1password/tap`, `ngrok/ngrok`, `steipete/tap`.
- `install_standalone_tools()` step in bootstrap for non-Homebrew tools (Amp via official install script with fail-safe URL check).
- `manual-installs.txt`: 1Password, Xcode, Docker, Google Drive, Amp with install reasons.

### Changed
- Brewfile: `node` replaced with `node@24` to match PATH configuration.
- Brewfile: `font-jetbrains-mono-nerd-font` now installed via Homebrew (was manually placed).
- Helium moved from `manual-installs.txt` to Brewfile (`helium-browser` cask).
- Brewfile is now the canonical source of truth — fully aligned with system state.

### Removed
- Brewfile: `curl` (system curl sufficient), `opencode` (unused), `1password` GUI cask (standalone installer preferred for biometrics/browser integration).

## [2.3.0] - 2026-02-21
### Added
- Terminal editor config managed through shell defaults.
- `$EDITOR` set per terminal: `cursor --wait` in vscode, `micro` elsewhere.

## [2.2.0] - 2026-02-21
### Added
- Stripped-down `config/starship-mobile.toml` for non-desktop terminals (no nerdfonts, no language detection, no time — safe for mosh).
- `TERM_PROGRAM`-based detection in `.zshenv`: ghostty and vscode get full starship config, everything else gets the mobile variant.
- `micro` added to Brewfile as terminal-based editor.

### Changed
- `open_in_editor` now routes by terminal: Cursor when inside vscode, micro everywhere else.

## [2.1.0] - 2026-02-20
### Added
- Conventional commit enforcement via `conventional-pre-commit` hook (commit-msg stage).
- Pre-push guard requiring a version tag and matching changelog entry when pushing to main (`setup/hooks/pre-push-main-guard.sh`).

## [2.0.1] - 2026-02-20
### Removed
- `secrets.zsh` mechanism — unused shell-level secrets file, example template, bootstrap logic, and `.zshrc` source line. API keys are handled by `load_key` (1Password) and machine-local app configs live in `~/.config/dotfiles-local/`.

## [2.0.0] - 2026-02-18
### Added
- Canonical root `Brewfile` for one-go future machine setup.
- Single bootstrap entrypoint at `setup/bootstrap.sh` with `--dry-run`, `--no-brew`, and `--no-link`.
- Repo-local skill set under `.agents/skills` and repo-local Claude symlink mirror under `.claude/skills`.
- Parent-navigation aliases: `...`, `....`, `.....`.
- Manual install checklist output in `setup/bootstrap.sh`, sourced from `setup/manual-installs.txt`.
- Editor fallback helper in `zsh/aliases.zsh` (`cursor` -> Cursor app -> `code` -> VS Code app -> `open`).
- `cw` command suite for Claude Code worktree+tmux workflow (`cw`, `cw-ls`, `cw-rm`, `cw-prune`, `cw-send`).
- Global gitignore (`git/ignore`) with `.worktrees/` entry, wired via `core.excludesfile`.

### Changed
- Setup flow is now a major-cut model centered on `setup/bootstrap.sh`.
- Main README updated for v2 setup flow.
- Cursor config linking in `setup/bootstrap.sh` is now conditional on Cursor being installed; bootstrap continues cleanly when Cursor is absent.
- README quick-start now includes the manual install review and rerun step (`./setup/bootstrap.sh --no-brew`) after manual app installs.
- Cursor entry in `setup/manual-installs.txt` now documents the post-install relink step.

### Fixed
- Unalias editor helpers before function definitions to prevent zsh load errors.

### Removed
- Split setup scripts and split Brewfiles from `zsh/setup` and `config/setup`.

## [1.0.0] - 2026-02-18
### Added
- Baseline tag for rollback before the v2 setup refactor.

### Changed
- Setup guide moved to the website and removed from this repository.
