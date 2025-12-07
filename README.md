# Dotfiles

My personal macOS configuration and setup automation.

## What This Is

A complete, reproducible system for setting up a new MacBook from scratch. Created primarily to eliminate the pain of manual configuration when migrating machines.

This is **v1** — expect frequent updates as I refine the workflow.

## Quick Start

**Full setup guide:** See [`setting-up-a-new-macbook.md`](setting-up-a-new-macbook.md)

**TL;DR:**

```bash
# 1. Clone this repo
git clone git@github.com:jwa91/dotfiles.git ~/dotfiles

# 2. Set up shell environment
cd ~/dotfiles/zsh/setup
./install-zsh.sh
./install-tools.sh

# 3. Set up applications
cd ~/dotfiles/config/setup
./install-apps.sh
./link-apps.sh
```

## What's Included

- **Shell**: Zsh with Starship prompt, FZF, curated plugins
- **Git**: Global config with commit templates
- **Terminal**: Ghostty configuration
- **Python**: Integration with [python-template](https://github.com/jwa91/python-template) for project scaffolding
- **Apps**: Configurations for Cursor, VS Code, Claude, Codex, and more
- **Security**: 1Password-based SSH agent setup

## Structure

```
dotfiles/
├── zsh/                    # Shell configuration
│   ├── setup/              # Installation scripts
│   └── zsh-functions/      # Custom functions
├── git/                    # Git configuration
├── config/                 # Application configs
│   ├── cursor/             # Cursor IDE
│   ├── claude/             # Claude Desktop
│   ├── claude-code/        # Claude Code CLI
│   ├── codex/              # Codex CLI
│   └── ...
└── setting-up-a-new-macbook.md
```

## Philosophy

- **Reproducible**: Complete automation from fresh macOS install
- **Modular**: Each component is independent
- **Secure**: with 1Password for SSH
- **Modern tooling**: uv, Bun, Starship, Ghostty

## TODO

- [ ] Add backup strategy for existing configs
- [ ] Health check utilities
- [ ] Unified MCP server management
- [ ] More granular Brewfile splitting
- [ ] Visual architecture documentation

## License

MIT — Use freely, but this is tailored to my specific workflow.
