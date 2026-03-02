# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project follows Semantic Versioning.

## [Unreleased]

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
- Fresh editor config managed via dotfiles symlink (`config/fresh/config.json`).
- `$EDITOR` set per terminal: `cursor --wait` in vscode, `fresh` in ghostty, `micro` elsewhere.
- Bootstrap links fresh config to `~/.config/fresh/config.json`.

## [2.2.0] - 2026-02-21
### Added
- Stripped-down `config/starship-mobile.toml` for non-desktop terminals (no nerdfonts, no language detection, no time — safe for mosh).
- `TERM_PROGRAM`-based detection in `.zshenv`: ghostty and vscode get full starship config, everything else gets the mobile variant.
- `micro` and `fresh-editor` added to Brewfile as terminal-based editors.

### Changed
- `open_in_editor` now routes by terminal: Cursor when inside vscode, fresh in ghostty, micro everywhere else.

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
