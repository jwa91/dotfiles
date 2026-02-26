---
name: install-software
description: REQUIRED before installing any package, tool, runtime, or application on this machine. Defines how and where software must be installed to keep the system aligned with dotfiles.
---

# How to Install Software on This Machine

This workstation uses `~/dotfiles` as the single source of truth for what is installed. All agents must follow these conventions. Installing software without updating dotfiles creates drift that breaks reproducibility.

## Rules

1. **Never install global packages without updating dotfiles.** If you install something via brew, it must be added to the Brewfile. If it's a manual install, it goes in `setup/manual-installs.txt`.
2. **Never use `pip install`, `npm install -g`, or `pnpm add -g` for tools.** Global package manager installs create invisible drift. Use the alternatives below.
3. **Prefer project-local over global.** Linters, formatters, and build tools belong in the project's `devDependencies` or `uv` environment — not installed globally.

## How to Install Things

### CLI tools and libraries
Use Homebrew. Add to `~/dotfiles/Brewfile`, then `brew bundle install --file ~/dotfiles/Brewfile`.

```
brew "ripgrep"          # formula for CLI tools
cask "some-app"         # cask for GUI apps
tap "org/repo"          # add tap first if needed
```

### GUI applications
Use Homebrew cask (same Brewfile). Only use manual install when there is a documented reason (see below).

### Python tools (ruff, mypy, etc.)
- **Project-local** (preferred): `uv add --dev ruff` or `uv run ruff`.
- **Cross-project** (rare): `uv tool install ruff` — managed by uv, not brew.
- **Never**: `pip install ruff` or `pip3 install`.

### JavaScript tools (biome, eslint, etc.)
- **Project-local** (preferred): `pnpm add -D biome` or project devDependencies.
- **Never**: `npm install -g` or `pnpm add -g`. Keep global package managers empty.

### Tools with official install scripts
Add to `install_standalone_tools()` in `setup/bootstrap.sh`. Must be:
- Skipped if already installed (`command -v`).
- Fail-safe (check URL reachability, warn and continue on failure).
- Also documented in `setup/manual-installs.txt`.

### Exceptions (manual installs)
Some apps are intentionally outside Homebrew. These are listed in `setup/manual-installs.txt` with reasons. Current exceptions:

| App | Reason |
|-----|--------|
| 1Password | Biometrics/browser extension integration breaks with brew cask |
| Cursor | App-managed CLI shim conflicts with brew symlinks |
| Docker | Brew cask needs sudo for /usr/local/bin, breaks non-interactive installs |
| Google Drive | Brew cask has chronic version-tracking failures |
| Tailscale | Network extension approval needs official installer |
| Xcode | Mac App Store only |
| Amp | Official install script is canonical method |

Do not add new exceptions without a clear reason.

## After Any Install

1. Verify the Brewfile matches reality: `brew bundle check --file ~/dotfiles/Brewfile`
2. Check for drift: `brew bundle cleanup --file ~/dotfiles/Brewfile`
3. Commit the Brewfile/manual-installs changes to dotfiles.

## Summary

| Want to install... | Do this | Don't do this |
|--------------------|---------|---------------|
| CLI tool | `brew` + Brewfile | `curl \| bash`, `go install` |
| GUI app | `brew --cask` + Brewfile | Download from website |
| Python tool | `uv tool install` or project-local | `pip install` |
| JS tool | Project devDependency | `npm install -g` |
| App with brew issues | `manual-installs.txt` with reason | Just install and forget |
