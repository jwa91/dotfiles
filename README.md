# dotfiles

Clean, bootstrappable macOS configuration for Apple Silicon machines.

The governing rule is: **every tool has exactly one owner**. Homebrew is the
base package/bootstrap layer, not the authority for fast-moving GUI app updates
or project runtime state.

See [docs/system.md](docs/system.md) for the full system model.

## Stack

| Layer | Owner |
|---|---|
| Base packages | [Brewfile](Brewfile) |
| GUI apps | App updater or Homebrew, per Brewfile comments |
| Containers | OrbStack |
| Shell | zsh, with shared environment kept separate from interactive behavior |
| Prompt/terminal | starship + Ghostty |
| Listings/help | eza + cheat/tldr/man |
| Task runner | just |
| Python | uv |
| TypeScript | mise-owned Node baseline + project pins; pnpm via Corepack |
| Go | mise-managed Go toolchain |
| Rust | mise-managed Rust; rustup is the backend implementation |
| Secrets/SSH | 1Password; Proton apps are installed but do not own secrets/SSH |
| Signing | GPG for code signing, SSH for Git/VPS access |

Project runtimes do not land in Homebrew. Homebrew installs their managers:
`mise` for Go/Rust/Node/Bun and `uv` for Python. Python work should be
expressed through `uv run`, `uv add`, `uv sync`, or `uvx`; bare `python` and
`pip` are guard shims, not resolvers. `UV_MANAGED_PYTHON=1` makes uv use
uv-owned interpreters instead of silently selecting system/framework Python.
Runtime policy shims live in `bin/shims/`. See
[ADR 0001](docs/adr/0001-python-runtime-ownership.md) for the Python runtime
policy, [docs/python.md](docs/python.md) for the uv + ty + Ruff workflow, and
[ADR 0002](docs/adr/0002-command-shim-authority.md) for shim authority.

mise provides one exact global Node baseline, while exact project `mise.toml`
pins override it. Dotfiles shims keep that selection transparent, allow
`node`/`npx` everywhere, and reject global npm/pnpm installs. pnpm versions
come from `package.json#packageManager` through Corepack; durable CLIs belong
in the Brewfile. The separately pinned mise-owned Bun host runtime remains
available, but is not the Node or package-dependency owner.

## New Machine

1. `xcode-select --install` — interactive GUI prompt; git needs the CLT.
2. `git clone https://github.com/jwa91/dotfiles ~/dotfiles` — HTTPS, no keys yet.
3. `cd ~/dotfiles && ./setup/bootstrap.sh` — dependency-free entrypoint for initialization and managed configuration.
4. Work through [setup/manual-installs.txt](setup/manual-installs.txt).
5. Sign in to 1Password and enable its SSH agent.
6. Switch the git remote to SSH.
7. Run `just doctor` until the managed state is clean.

## Daily Commands

- `just` — list available dotfile tasks.
- `just bootstrap` — converge a new or existing machine.
- `just init` — install or initialize managed machine capabilities.
- `just set` — converge repository-controlled configuration.
- `just doctor` — check links, package presence, runtime leaks, and app state.
- `just default-apps` — make Zed the default for managed text/code file types.
- `just project-audit` — report project runtime ownership drift under `~/developer`.
- `just toolchains` — install repo-declared mise toolchains.
- `just brew-sync` — install missing Brewfile entries without upgrading apps.
- `just brew-vulns` — check Brewfile formulae against OSV using Homebrew 6.
- `just brew-outdated` / `brewoutdated` — show Homebrew-owned updates only.
- `just brew-upgrade` / `brewup` — upgrade Homebrew-owned packages while
  leaving self-updating GUI apps to their own updater.
- `brewsync` — shell alias for the same Homebrew presence check.
