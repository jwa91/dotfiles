# Dotfiles

My personal macOS configuration and setup automation.

## What This Is

A complete, reproducible system for setting up a new MacBook from scratch. Created primarily to eliminate the pain of manual configuration when migrating machines.

Current major release: **v2**.

## Quick Start

**Full setup guide:** [janwillemaltink.com/writings/new-macbook-guide](https://janwillemaltink.com/writings/new-macbook-guide/)

**TL;DR:**

```bash
# 1. Clone this repo
git clone git@github.com:jwa91/dotfiles.git ~/dotfiles

# 2. Review manual installs (outside Homebrew)
cd ~/dotfiles
cat ./setup/manual-installs.txt

# 3. Run one bootstrap command
./setup/bootstrap.sh

# 4. After installing manual apps later, relink app configs
./setup/bootstrap.sh --no-brew
```

Bootstrap flags:

```bash
./setup/bootstrap.sh --dry-run
./setup/bootstrap.sh --no-brew
./setup/bootstrap.sh --no-link
```

Manual-install checklist: `setup/manual-installs.txt`  
Bootstrap will warn about items in this list and skip Cursor linking until Cursor is installed.

## What's Included

- **Shell**: Zsh with Starship prompt, FZF, curated plugins
- **Git**: Global config with commit templates
- **Terminal**: Ghostty configuration
- **Python**: Integration with [python-template](https://github.com/jwa91/python-template) for project scaffolding
- **Apps**: Configurations for Cursor, VS Code, Claude, Codex, and more
- **Manual app installs**: Checklist for tools intentionally managed outside Homebrew
- **Security**: 1Password-based SSH agent setup

## Structure

```
dotfiles/
├── Brewfile
├── CHANGELOG.md
├── README.md
├── setup/
│   └── bootstrap.sh
├── .agents/
│   └── skills/
├── .claude/
│   └── skills/             # Repo-local symlinks to .agents/skills
├── git/                    # Git configuration
│   ├── config
│   ├── commit_template.txt
│   └── setup.sh
├── zsh/                    # Shell configuration
│   ├── .zshenv
│   ├── .zshrc
│   ├── .zprofile
│   ├── aliases.zsh
│   ├── completions.zsh
│   ├── functions.zsh
│   ├── options.zsh
│   ├── plugins.zsh
│   ├── prompt.zsh
│   ├── setup/
│   │   └── secrets.example.zsh
│   └── zsh-functions/      # Custom functions
│       ├── general-functions.zsh
│       ├── nextjs-functions.zsh
│       └── agentskills-functions.zsh
└── config/                 # Application configs
    ├── tmux/
    ├── cursor/
    ├── vscode/
    ├── claude/
    ├── claude-code/
    ├── codex/
    ├── gh/
    └── ...
```

## Philosophy

- **Reproducible**: Complete automation from fresh macOS install
- **Modular**: Each component is independent
- **Secure**: with 1Password for SSH
- **Modern tooling**: uv, Bun, Starship, Ghostty

## Secret-Safe Config Model

- Live, machine-specific app configs live outside git in `~/.config/dotfiles-local`.
- Tracked config templates live in this repo as `*.example.*` files.
- `setup/bootstrap.sh` bootstraps missing local runtime files from examples and links app paths.
- Local commit protection is enabled with `pre-commit` + `gitleaks`:
  - `pre-commit install`
  - `pre-commit run --all-files`

## Versioning

- Baseline snapshot is tagged `v1.0.0`.
- Major setup refactor is tagged `v2.0.0`.
- New releases follow semantic versioning and are recorded in `CHANGELOG.md`.

## TODO

- [ ] Add backup strategy for existing configs
- [ ] Health check utilities
- [ ] Unified MCP server management
- [ ] Visual architecture documentation

## License

MIT — Use freely, but this is tailored to my specific workflow.
