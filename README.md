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
| TypeScript | Node via project pins; pnpm by default; Bun global for host `bunx` |
| Go | mise-managed Go toolchain |
| Rust | mise-managed Rust; rustup is the backend implementation |
| Secrets/SSH | 1Password; Proton apps are installed but do not own secrets/SSH |
| Signing | GPG for code signing, SSH for Git/VPS access |

Project runtimes do not land in Homebrew. Homebrew owns only the managers:
`mise` for Go/Rust/Node/Bun and `uv` for Python. Outside a project, bare
`python`, `pip`, `node`, `npm`, and `pnpm` should not become accidental global
state. Bun is the one deliberate exception: it is a declared global in
`config/mise/config.toml` so host tooling (Claude Code MCP servers) can reach
`bunx` — owned and version-pinned by mise, never installed via Homebrew or the
official `~/.bun` installer.

## New Machine

1. `xcode-select --install` — interactive GUI prompt; git needs the CLT.
2. `git clone https://github.com/jwa91/dotfiles ~/dotfiles` — HTTPS, no keys yet.
3. `cd ~/dotfiles && ./setup/bootstrap.sh` — Homebrew, base packages, links, zsh.
4. Work through [setup/manual-installs.txt](setup/manual-installs.txt).
5. Sign in to 1Password and enable its SSH agent.
6. Switch the git remote to SSH.
7. Run `just doctor` until the managed state is clean.

## Daily Commands

- `just` — list available dotfile tasks.
- `just bootstrap` — converge a new or existing machine.
- `just doctor` — check links, package presence, runtime leaks, and app state.
- `just toolchains` — install repo-declared mise toolchains.
- `just brew-sync` — install missing Brewfile entries without upgrading apps.
- `brewsync` — shell alias for the same Homebrew presence check.
