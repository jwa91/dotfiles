# Dotfiles

My personal macOS configuration and setup automation.

## What This Is

A complete, reproducible system for setting up a new MacBook from scratch. Created primarily to eliminate the pain of manual configuration when migrating machines.

This is **v1** — expect frequent updates as I refine the workflow.

## Quick Start

**Full setup guide:** [janwillemaltink.com/writings/new-macbook-guide](https://janwillemaltink.com/writings/new-macbook-guide/)

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

# 4. Enable local secret scanning before commits
cd ~/dotfiles
pre-commit install
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
├── README.md
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
│   ├── setup/              # Installation scripts
│   │   ├── Brewfile
│   │   ├── install-zsh.sh
│   │   ├── install-tools.sh
│   │   └── secrets.example.zsh
│   └── zsh-functions/      # Custom functions
│       ├── general-functions.zsh
│       ├── nextjs-functions.zsh
│       └── agentskills-functions.zsh
└── config/                 # Application configs
    ├── setup/
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
- `config/setup/link-apps.sh` bootstraps missing local runtime files from examples.
- Local commit protection is enabled with `pre-commit` + `gitleaks`:
  - `pre-commit install`
  - `pre-commit run --all-files`

## TODO

- [ ] Add backup strategy for existing configs
- [ ] Health check utilities
- [ ] Unified MCP server management
- [ ] More granular Brewfile splitting
- [ ] Visual architecture documentation

## License

MIT — Use freely, but this is tailored to my specific workflow.
