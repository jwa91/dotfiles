# Dotfiles

My personal macOS configuration and setup automation.

## What This Is

A complete, reproducible system for setting up a new MacBook from scratch. Created primarily to eliminate the pain of manual configuration when migrating machines.

Current major release: **v2**.

## Quick Start

**Full setup guide for v1:** [janwillemaltink.com/writings/new-macbook-guide](https://janwillemaltink.com/writings/new-macbook-guide/)

**New Mac setup:**

```bash
# 1. Install Xcode CLI tools (required before anything else)
xcode-select --install

# 2. Clone this repo (uses HTTPS — SSH keys aren't set up yet)
git clone https://github.com/jwa91/dotfiles.git ~/dotfiles

# 3. Run bootstrap (installs Homebrew, all packages, links configs)
cd ~/dotfiles
./setup/bootstrap.sh

# 4. Install manual apps (see list printed by bootstrap, or:)
cat ./setup/manual-installs.txt

# 5. After installing manual apps, relink their configs
./setup/bootstrap.sh --no-brew
```

Bootstrap flags:

```bash
./setup/bootstrap.sh              # Full setup
./setup/bootstrap.sh --dry-run    # Preview without changes
./setup/bootstrap.sh --no-brew    # Skip Homebrew (relink only)
./setup/bootstrap.sh --no-link    # Skip symlinks (brew only)
```

Bootstrap will print a checklist of manual installs and skip Cursor config linking until Cursor is detected.

## What's Included

- **Brewfile**: Canonical package manifest — CLI tools, runtimes, casks, fonts
- **Shell**: Zsh with Starship prompt, FZF, curated plugins
- **Git**: Global config with commit templates and conventional commit enforcement
- **Terminal**: Ghostty configuration with terminal-aware editor routing
- **Tmux**: Session bookmarks, project layouts, and interactive picker
- **AI tools**: Settings for Claude Code (config files only — agent resources live elsewhere)
- **Apps**: Cursor, VS Code, and more with symlinked settings
- **Manual installs**: Checklist for tools outside Homebrew (1Password, Cursor, Docker, Xcode, etc.)
- **Security**: 1Password-based SSH agent and secret-safe config model

## Structure

```
dotfiles/
├── Brewfile                    # Canonical package manifest
├── CHANGELOG.md
├── README.md
├── setup/
│   ├── bootstrap.sh            # Main setup entrypoint
│   └── manual-installs.txt     # Tools outside Homebrew
├── git/                        # Git configuration
│   ├── config
│   ├── commit_template.txt
│   └── ignore
├── zsh/                        # Shell configuration
│   ├── .zshenv                 # PATH, env vars, terminal detection
│   ├── .zshrc
│   ├── .zprofile
│   ├── aliases.zsh
│   ├── completions.zsh
│   ├── functions.zsh
│   ├── options.zsh
│   ├── plugins.zsh
│   ├── prompt.zsh
│   └── zsh-functions/
├── config/                     # Application configs
│   ├── ghostty/
│   ├── tmux/
│   ├── starship.toml
│   ├── starship-mobile.toml
│   ├── fresh/
│   ├── cursor/
│   ├── vscode/
│   ├── claude-code/            # settings.json only
│   ├── cheat/
│   └── gh/
├── docs/                       # Reference documentation
└── .agents/skills/             # Agent skills for working on this repo
    ├── understand-dotfiles/
    ├── modify-dotfiles-config/
    ├── modify-dotfiles-zsh/
    └── install-software/
```

Skills are stored in `.agents/skills/` and symlinked into `.claude/skills/` so Claude Code picks them up. They teach agents how this repo works — setup flow, symlink behavior, naming conventions, and package management rules.

## Naming Conventions

All aliases and functions follow: **action prefix + shortest target, mashed together** (no hyphens or underscores). Private helpers start with `_`.

| Prefix | Action                    | Examples                                         |
| ------ | ------------------------- | ------------------------------------------------ |
| `mk`   | make/create/generate      | `mkpass`, `mkroute`, `mkskill`                   |
| `e`    | edit/open in editor       | `ezsh`, `edots`, `evault`, `edev`                |
| `cd`   | navigate to directory     | `cdd`, `cdzsh`, `cddots`, `cdvault`              |
| `t`    | tmux operation            | `tmain`, `tls`, `tpick`                          |
| `py`   | python                    | `pyclean`                                        |
| —      | standalone (clear enough) | `reload`, `reloadenv`, `key`, `rwe`, `zshdoctor` |

When adding new commands: pick the action prefix first, then the shortest unambiguous target. If an `e` variant exists, add a matching `cd` variant.

## Local Repo Layout

- `DEV_DIR` is the canonical root for local source checkouts.
- Default resolution is `~/developer` when that directory exists, otherwise `~/Developer`.
- `mkskill` prefers a local `agentskills` checkout at `$DEV_DIR/agentskills` and falls back to the public GitHub repo when no local checkout exists.

## Philosophy

- **Reproducible**: Complete automation from fresh macOS install
- **Modular**: Each component is independent
- **Secure**: with 1Password for SSH
- **Modern tooling**: uv, Bun, Starship, Ghostty

## Config Boundary

This repo manages **classic config files only** — settings, preferences, keybindings. Things like agent skills, instructions (AGENTS.md, CLAUDE.md), commands, and rules are agent resources and belong in a dedicated AI repo, not here.

For CLI-family ownership and local repo layout conventions, see
`docs/cli-boundary-and-layout.md`.

Auth tokens and secrets stay in their default home directory locations (e.g. `~/.codex/auth.json`, `~/.claude.json`) and are never symlinked or tracked. See `docs/macos-config-locations.md` for a reference of where macOS apps store config.

Local commit protection is enabled with `prek` + `gitleaks`:
- `prek install`
- `prek run --all-files`

## Versioning

- Baseline snapshot is tagged `v1.0.0`.
- Major setup refactor is tagged `v2.0.0`.
- New releases follow semantic versioning and are recorded in `CHANGELOG.md`.

## License

MIT — Use freely, but this is tailored to my specific workflow.
