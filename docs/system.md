# System Model

## Ownership Rules

| Thing | Owner | Notes |
|---|---|---|
| Base CLI packages | Homebrew | Installed from `Brewfile`; upgraded deliberately. |
| GUI apps | App updater or Homebrew, per cask | Brew may bootstrap both; ownership is listed below. |
| Containers | OrbStack | Target replacement for Docker Desktop on macOS. |
| Python projects | uv | Owns Python versions, virtualenvs, dependencies, and locks. |
| TypeScript projects | mise + pnpm/Bun | mise activates project tooling; global Bun supports host `bunx`. |
| Go projects | mise | mise owns Go versions; projects can still use Go modules/toolchain directives. |
| Rust projects | mise | mise owns Rust version selection; rustup is the backend implementation. |
| Shell | zsh | Keep shared environment separate from interactive shell behavior. |
| Tasks | just | Human interface for bootstrap, checks, and maintenance. |
| Command help | cheat + tldr + man | Personal sheets document local workflow; upstream examples are cloned/cached. |
| Secrets/SSH | 1Password | Proton apps may be installed, but 1Password owns secrets and SSH. |
| Code signing | GPG | SSH is for transport and machine access. |

## Homebrew

Homebrew installs missing host packages and casks. It does not own project
runtime versions, and it does not decide when casks with their own updater are
fresh.

Do:

- Put stable CLI tools in `Brewfile`.
- Put casks in `Brewfile` when that makes new-machine setup faster or when
  Homebrew is the app's update owner.
- Run `just brew-sync` to install missing entries without upgrading casks.
- Run `brew upgrade` deliberately for the CLI layer. Interactive shells export
  `HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1` so apps with their own updater
  stay app-owned.

Do not:

- Add `node`, `python`, `rust`, `rustup`, or `go` to Homebrew.
- Use `brew upgrade --greedy` as a general maintenance habit.
- Let Homebrew cleanup remove GUI apps automatically.

Manual and non-Brew installs live in `setup/manual-installs.txt`.

## Containers

OrbStack is the container runtime on macOS. Docker Desktop should be absent;
`just doctor` warns if the app, support data, or privileged helpers reappear.

On macOS, Docker-compatible containers run inside a Linux VM. The Docker socket
is still a powerful control surface, so treat access to it as privileged even
when commands are run by an ordinary user. Do not share the socket broadly and
avoid bind-mounting sensitive host directories into containers by default.

The zsh PATH prefers OrbStack's bundled Docker-compatible CLI at
`/Applications/OrbStack.app/Contents/MacOS/xbin` ahead of `/usr/local/bin`.

## Shells

zsh is the primary shell. Shared environment stays separate from interactive
zsh behavior:

- Paths and exported directories are shared.
- Interactive aliases, plugins, and completion behavior stay shell-specific.
- No shell framework is used.
- Plugins are explicit and deliberately installed.

Shell functions are only for behavior that must mutate or intercept the parent
interactive shell, such as `cd`, `export`, or toolchain command wrappers.
Standalone helpers live in `bin/`. Command-shadowing policy wrappers live in
`bin/shims/`. Bootstrap links executables from both locations into
`~/.local/bin`.

Interactive zsh re-prepends `~/.local/bin` after `mise activate zsh`, so
dotfiles shims remain the command authority while mise remains the runtime
selector. See [ADR 0002](adr/0002-command-shim-authority.md).

## Command Help

Personal `cheat` sheets should document local workflows, aliases, and dotfiles
policy only. Do not mirror upstream app manuals there; those drift quickly.

Use `how <topic>` for lookup. It tries personal/community `cheat` sheets first,
then `tldr`, then `man`. Bootstrap and `just help` clone/update the community
`cheat` sheets and refresh the tldr cache.

## Runtimes

Python:

- `uv` owns Python projects.
- `UV_MANAGED_PYTHON=1` requires uv-managed interpreters, so `uv run` does not
  silently select system/framework Python.
- Use `uv run script.py` for scripts, `uv run python` for REPL/`-c`/`-m`,
  `uv add` for project dependencies, and `uv sync` for environments.
- Use `uvx` (`uv tool run`) for one-off Python CLIs and `uv tool install` for
  durable personal Python CLIs.
- Bare `python`, `python3`, `pip`, and `pip3` are guard shim commands, not
  resolvers. They do not choose a global interpreter or install into ambient
  state.
- Use `uv pip ...` only for explicit legacy/manual virtualenv workflows.
- Project dependencies live in the project lockfile.
- See [ADR 0001](adr/0001-python-runtime-ownership.md) for the full policy.

TypeScript:

- `mise` owns Node versions per project.
- `package.json#packageManager` owns the package-manager version.
- Dotfiles shim commands route `node`, `npm`, `npx`, and `pnpm` through the
  active project Node. `pnpm` runs through Corepack so packageManager stays
  the package-manager authority. These shims intentionally stay ahead of mise's
  activated project bin directory in interactive zsh.
- `just project-audit` reports packageManager projects without a tracked exact
  `mise.toml` Node pin.
- `bun` has a repo-declared global baseline for host `bunx` escape hatches.
  Project commands still go through project dependencies, package-manager
  scripts, or pinned project tooling.
- Do not use `bun upgrade`; use `mise upgrade bun` or change mise config.
- Do not use global `npm`, `pnpm`, or `bun` package installs. Use project
  dependencies, mise's `npm:` backend for reusable JS CLIs, or the Brewfile.
  mise's `bun@<version>` backend owns the Bun runtime; there is no `bun:`
  package backend.

Go:

- `mise` owns Go versions.
- The global baseline is declared in `config/mise/config.toml`.
- Project expectations can be pinned with project `mise.toml` or
  `.go-version`; `go.mod` and `go.work` toolchain directives are honored by
  Go itself after mise selects the baseline Go binary.
- Use Go modules for dependencies.
- Do not use `go install` for durable CLI installs; use `go build` or `go run`
  for project-local binaries, and use the mise `go:` backend or the Brewfile
  for reusable CLIs.
- Do not use `go env -w`; persistent Go environment belongs in mise config,
  shell env, or project config.

Rust:

- `mise` owns Rust version selection.
- `rustup` remains the backend implementation and may use `~/.rustup` and
  `~/.cargo`.
- The global baseline is declared in `config/mise/config.toml`.
- Toolchain components and targets belong in mise tool options.
- Do not use `cargo install` for global CLIs; use the mise `cargo:` backend or
  add the tool to the Brewfile. For an intentional one-off local install, type
  the explicit shell escape hatch: `command cargo install --path .`.

## Bootstrap Contract

A new machine should need:

1. Apple Command Line Tools.
2. This repository cloned to `~/dotfiles`.
3. `./setup/bootstrap.sh`.
4. Manual sign-ins and app approvals from `setup/manual-installs.txt`.
5. `just doctor`.

Anything else is drift and should either become explicit here or be removed.
