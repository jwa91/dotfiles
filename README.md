# Dotfiles

Personal macOS dotfiles for my workstation setup.

The current direction is clearer ownership:

- Brew manages workstation tools and selected apps.
- Active language runtimes, package managers, formatters, linters, and release tools are owned by projects, not installed globally by bootstrap.
- This repo may still keep reusable project defaults, templates, and reference configs, but bootstrap should not install or link them globally by default.
- GitHub and self-hosted Forgejo are both first-class git hosts for my own work.
- Bootstrap should create the current machine shape, not preserve a log of old repo decisions.

## Quick Start

```bash
xcode-select --install
git clone https://github.com/jwa91/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup/bootstrap.sh
```

Useful bootstrap modes:

```bash
./setup/bootstrap.sh --dry-run
./setup/bootstrap.sh --no-brew
./setup/bootstrap.sh --no-link
./setup/bootstrap.sh --reset
./setup/bootstrap.sh --update
```

Bootstrap installs Homebrew if needed, applies the root `Brewfile`, links managed config files, and prints the manual install checklist from `setup/manual-installs.txt`.

## Managed Shape

```text
dotfiles/
├── Brewfile
├── setup/
│   ├── bootstrap.sh
│   └── manual-installs.txt
├── hooks/
│   └── pre-push-main-guard.sh
├── git/
│   ├── config
│   ├── commit_template.txt
│   └── ignore
├── zsh/
│   ├── .zshenv
│   ├── .zshrc
│   ├── aliases.zsh
│   ├── completions.zsh
│   ├── functions.zsh
│   ├── options.zsh
│   ├── plugins.zsh
│   ├── prompt.zsh
│   └── zsh-functions/
├── config/
│   ├── atuin/
│   ├── broot/
│   ├── cheat/
│   ├── claude-code/
│   ├── cursor/
│   ├── ghostty/
│   ├── tmux/
│   ├── starship.toml
│   └── starship-mobile.toml
├── docs/adr/
├── templates/                  # Optional project defaults and grab-ready config snippets
└── .agents/skills/
```

## Package Policy

The `Brewfile` is a workstation manifest. It should contain tools and apps that make the laptop usable across projects.

Keep in Brew:

- Shell/workstation tools: `git`, `tmux`, `starship`, `fzf`, `ripgrep`, `jq`, `shellcheck`, `gitleaks`, `prek`
- Navigation/history tools: `zoxide`, `atuin`, `broot`, `cheat`
- Git host tools that match the real setup, including Forgejo tooling
- Selected apps and fonts that are genuinely part of the workstation baseline

Keep out of Brew by default:

- Language runtimes and package managers such as Node, pnpm, Bun, uv, Go, Rust/Cargo
- Project formatters, linters, release tools, and framework helpers
- One-off apps and services that are easy to reinstall when needed

Keeping something out of Brew does not mean it is banned from this repo. A Ruff,
Biome, GitHub Actions, Forgejo Actions, or language-specific default can live
here as a passive template if it is useful to copy into a project. The boundary
is automatic ownership: Brew/bootstrap should not make that tooling global or
active unless it is genuinely workstation-level.

Project lockfiles choose package managers: `pnpm-lock.yaml` means `pnpm`, `package-lock.json` means `npm`, and `bun.lock` means `bun`. Python projects should carry their own `uv` setup. Prefer ephemeral runners for one-off commands: `uvx`, `npx`, `pnpm dlx`, `bunx`, or `go run package@version`.

## Git Hosting

Do not assume new self-built projects live on GitHub. Some projects live on self-hosted Forgejo, and Forgejo is equal to GitHub for this machine's git workflow.

The Codeberg-hosted tap for `forgejo-cli-plus` is intentional:

```ruby
tap "stalecontext/forgejo-cli-plus", "https://codeberg.org/stalecontext/homebrew-forgejo-cli-plus.git"
```

That explicit URL is required because normal Homebrew tap shorthand assumes GitHub.

## Shell Commands

Aliases and functions use action prefix plus the shortest clear target, mashed together.

| Prefix | Action | Examples |
| --- | --- | --- |
| `mk` | make/create | `mkpass`, `mkskill` |
| `e` | edit/open | `ezsh`, `edots`, `evault`, `edev` |
| `cd` | navigate | `cdd`, `cdzsh`, `cddots`, `cdvault` |
| `t` | tmux | `tmain`, `tls` |
| `py` | python | `pyclean` |

When adding or removing shell commands, keep `config/cheat/cheatsheets/zsh` in sync.

## Config Boundary

This repo has two kinds of content:

- **Active machine config**: shell, git, terminal, selected editor settings, selected CLI/app config, and bootstrap behavior.
- **Passive project material**: templates, example configs, and reference defaults that can be copied into projects when needed.

Only active machine config should be linked by bootstrap. Passive project material should stay opt-in by being copied or selected explicitly.

Runtime auth files and secrets stay in their app-owned locations and are never tracked. Examples include `~/.codex/auth.json`, `~/.claude.json`, local MCP config, package-manager auth files, and anything containing tokens.

Agent skills in `.agents/skills/` are part of this repo because they teach agents how to modify this repo safely.

## Validation

Common checks:

```bash
bash -n setup/bootstrap.sh
zsh -n zsh/.zshenv zsh/.zshrc zsh/*.zsh zsh/zsh-functions/*.zsh
shellcheck setup/bootstrap.sh hooks/pre-push-main-guard.sh
./setup/bootstrap.sh --dry-run --no-brew
brew bundle check --file Brewfile
```

Local commit protection is managed by `prek.toml`:

```bash
prek install
prek run --all-files
```

## License

MIT. This repo is public but tuned to my machine and workflow.
