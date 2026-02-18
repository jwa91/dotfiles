# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project follows Semantic Versioning.

## [2.0.0] - 2026-02-18
### Added
- Canonical root `Brewfile` for one-go future machine setup.
- Single bootstrap entrypoint at `setup/bootstrap.sh` with `--dry-run`, `--no-brew`, and `--no-link`.
- Repo-local skill set under `.agents/skills` and repo-local Claude symlink mirror under `.claude/skills`.
- Parent-navigation aliases: `...`, `....`, `.....`.

### Changed
- Setup flow is now a major-cut model centered on `setup/bootstrap.sh`.
- Main README updated for v2 setup flow.

### Removed
- Split setup scripts and split Brewfiles from `zsh/setup` and `config/setup`.

## [1.0.0] - 2026-02-18
### Added
- Baseline tag for rollback before the v2 setup refactor.

### Changed
- Setup guide moved to the website and removed from this repository.
