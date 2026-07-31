# System Model

## Ownership Rules

| Thing | Owner | Notes |
|---|---|---|
| Base CLI packages | Homebrew | Installed from `Brewfile`; upgraded deliberately. |
| GUI apps | App updater or Homebrew, per cask | Brew may bootstrap both; ownership is listed below. |
| Containers | OrbStack | Target replacement for Docker Desktop on macOS. |
| Python projects | uv | Owns Python versions, virtualenvs, dependencies, and locks. |
| TypeScript projects | mise + pnpm | Global Node baseline, exact project overrides, pnpm via Corepack. |
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

- Prefer `homebrew/core`; declare and explicitly trust every third-party tap.
- Put durable CLI tools in `Brewfile`.
- Put casks in `Brewfile` when that makes new-machine setup faster or when
  Homebrew is the app's update owner.
- Run `just brew-sync` to install missing entries without upgrading casks.
- Run `just brew-vulns` for Homebrew 6's OSV-backed formula check.
- Run `brewup` (or `just brew-upgrade`) for routine upgrades. Interactive
  shells export
  `HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1` so apps with their own updater
  stay app-owned.

Do not:

- Add `node`, `python`, `rust`, `rustup`, or `go` to Homebrew.
- Treat `brew x` as disposable: it leaves a normal formula installation behind,
  which must be promoted to the Brewfile or removed.
- Use `brew upgrade --greedy`, `--greedy-auto-updates`, or explicitly named
  self-updating casks as a general maintenance habit; those are deliberate
  escape hatches for repair.
- Let Homebrew cleanup remove GUI apps automatically.

Manual and non-Brew installs live in `setup/manual-installs.txt`.

## Containers

OrbStack is the container runtime on macOS. Docker Desktop and Podman Desktop
should be absent; `just doctor` warns if either app, its support data, or
privileged helpers reappear.

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

Shell functions are only for behavior that must mutate the parent interactive shell, such as `cd` or `export`. Public standalone commands live in `bin/`.

Command-shadowing policy wrappers live in `bin/shims/`. Bootstrap links executables from both locations into `~/.local/bin`.

Private shared Bash code lives in `lib/dotfiles/`; internal executables live in `libexec/dotfiles/` and are invoked by public commands or managed configuration, not linked onto PATH.

Command placement follows these rules:

- An alias is a shorter spelling for one command.
- A zsh function is used only when behavior must change the current shell.
- A `bin/` command is a stable standalone interface intentionally exposed on `PATH` for direct use by people or automation; configuration-specific adapters and implementation helpers do not belong there.
- A `just` recipe is a named workstation maintenance task.

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
- `ty` owns type checking and Python language intelligence; Ruff owns linting,
  import sorting, and formatting. Strict user-level fallbacks are managed under
  `~/.config/{ty,ruff}`, while project configuration remains authoritative.
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
- See [the Python workflow](python.md) for Zed and portable project settings.
- See [ADR 0001](adr/0001-python-runtime-ownership.md) for the full policy.

TypeScript:

- `mise` owns one exact global Node baseline and exact project overrides.
- `package.json#packageManager` owns pnpm versions through Corepack.
- Dotfiles shim commands route `node`, `npm`, `npx`, and `pnpm` through the
  active mise Node. They stay ahead of mise's activated project bin directory
  so global npm/pnpm installs remain unavailable without making normal runtime
  use project-only.
- Use `npx` or `pnpm dlx` for intentional cache-backed one-off execution.
- `just project-audit` reports packageManager projects without a tracked exact
  `mise.toml` Node pin.
- Bun remains a separately pinned mise-owned host runtime; `bun upgrade` and
  global Bun package installs remain guarded.
- Do not use global npm/pnpm installs. Use project dependencies, a one-off
  runner, or the Brewfile for durable CLIs.

Go:

- `mise` owns Go versions.
- The global baseline is declared in `config/mise/config.toml`.
- Project expectations can be pinned with project `mise.toml` or
  `.go-version`; `go.mod` and `go.work` toolchain directives are honored by
  Go itself after mise selects the baseline Go binary.
- Use Go modules for dependencies.
- Do not use `go install` for durable CLI installs; use `go build` or `go run` for project-local binaries, and use the Brewfile for reusable machine CLIs.
- Do not use `go env -w`; persistent Go environment belongs in mise config, `zsh/env.zsh`, or project config.

Rust:

- `mise` owns Rust version selection.
- `rustup` remains the backend implementation and may use `~/.rustup` and
  `~/.cargo`.
- The global baseline is declared in `config/mise/config.toml`.
- Toolchain components and targets belong in mise tool options.
- Do not use `cargo install` for global CLIs; add reusable machine CLIs to the Brewfile. For an intentional bypass, invoke the mise-owned command explicitly with `mise exec -- cargo install <args>`.

## Bootstrap Contract

Setup is lifecycle-first:

- `setup/init.sh` installs or initializes machine capabilities and is additive and idempotent.
- `setup/set.sh` converges repository-controlled configuration and does not install capabilities.
- `setup/doctor.sh` inspects state by domain and never repairs it.
- `setup/lib/` contains only shared primitives and declarations used across lifecycle stages.
- `setup/init/`, `setup/set/`, and `setup/doctor/` contain private modules owned by their matching entrypoint.
- `just` is the preferred interface after installation, but every recipe delegates to the shell entrypoints and those scripts never require `just`.
- `setup/bootstrap.sh` is the dependency-free new-machine entrypoint and runs `init`, then `set`, then prints the manual checklist.

A new machine should need:

1. Apple Command Line Tools.
2. This repository cloned to `~/dotfiles`.
3. `./setup/bootstrap.sh`.
4. Manual sign-ins and app approvals from `setup/manual-installs.txt`.
5. `just doctor`.

Anything else is drift and should either become explicit here or be removed.
