# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project follows Semantic Versioning.

## [Unreleased]

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
