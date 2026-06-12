# System Model

## Ownership Rules

| Thing | Owner | Notes |
|---|---|---|
| Base CLI packages | Homebrew | Installed from `Brewfile`; upgraded deliberately. |
| GUI apps | The app itself | Brew casks may bootstrap an app, but the app's updater owns freshness. |
| Containers | OrbStack | Target replacement for Docker Desktop on macOS. |
| Python projects | uv | Owns Python versions, virtualenvs, dependencies, and locks. |
| TypeScript projects | mise + pnpm/Bun | mise activates Node/tooling per project; pnpm is default, Bun is intentional. |
| Go projects | Go toolchain | Use official Go, modules, and `toolchain` in `go.mod`/`go.work`. |
| Rust projects | rustup | Homebrew does not own Rust toolchains. |
| Shell | zsh now, portable env later | Keep shared environment separate from interactive zsh behavior. |
| Tasks | just | Human interface for bootstrap, checks, and maintenance. |
| Secrets/SSH | 1Password | Proton Pass stays installed as an experiment, not a dependency. |
| Code signing | GPG | SSH is for transport and machine access. |

## Homebrew Policy

Homebrew installs missing host packages and stable bootstrap casks. It does not
own project runtime versions and it does not decide when self-updating apps are
fresh.

Do:

- Put stable CLI tools in `Brewfile`.
- Put bootstrap casks in `Brewfile` when that makes new-machine setup faster.
- Run `just brew-sync` to install missing entries without upgrading casks.
- Run `brew upgrade` deliberately for the CLI layer. Interactive shells export
  `HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1` so apps with their own updater
  stay app-owned.

Do not:

- Add `node`, `python`, `rust`, or `go` to Homebrew.
- Use `brew upgrade --greedy` as a general maintenance habit.
- Let Homebrew cleanup remove GUI apps automatically.

## Direct Apps

Direct apps are applications whose own updater is the update authority. Some
may still be installed by a Homebrew cask during bootstrap, but they are not
maintained by repeated Brewfile upgrades.

Current direct-app set:

- Ghostty
- Cursor
- Raycast
- 1Password
- Proton Pass, installed but out of scope for the current secrets plan
- OrbStack

Possible trials:

- Zed, as a lower-memory editor alternative to Cursor

## Containers

OrbStack is the target container runtime on macOS. Docker Desktop should be
absent after migration; `just doctor` warns if the app, support data, or old
privileged helpers reappear.

On macOS, Docker-compatible containers run inside a Linux VM. The Docker socket
is still a powerful control surface, so treat access to it as privileged even
when commands are run by an ordinary user. Do not share the socket broadly and
avoid bind-mounting sensitive host directories into containers by default.

The zsh PATH prefers OrbStack's bundled Docker-compatible CLI at
`/Applications/OrbStack.app/Contents/MacOS/xbin` ahead of Docker Desktop's old
`/usr/local/bin/docker` symlink.

## Accounts And Privileges

Do not enable the macOS root user as part of this setup. It creates more risk
than clarity on a personal developer machine.

The cleaner model is:

- Keep one administrator account for system changes.
- Use the daily account as a standard user if you want stricter separation.
- Escalate with macOS authorization prompts or `sudo` only when needed.
- Keep container access limited to the daily user that owns the development
  workspace.

Linux VPS machines can be stricter: prefer a non-root login user, SSH keys,
`sudo`, and rootless containers where practical.

## Shells

zsh is the primary shell. The shared environment should stay small enough to be
ported to bash and fish later:

- Paths and exported directories are shared.
- Interactive aliases, plugins, and completion behavior stay shell-specific.
- No shell framework is used.
- Plugins are explicit and deliberately installed.

## Runtime Rules

Python:

- `uv` owns Python projects.
- Bare `python` and `pip` are nudged away in interactive zsh.
- Project dependencies live in the project lockfile.

TypeScript:

- `mise` activates Node and package-manager versions per project.
- `pnpm` is the default package manager.
- `bun` is used when the project intentionally uses Bun runtime/tooling.

Go:

- Install the official Go toolchain archive under `~/.local/share/go`.
- Use `/usr/local/go` only for an admin-managed system install.
- Pin project expectations with `go.mod` or `go.work`.
- Use Go modules for dependencies.

Rust:

- Install through `rustup`.
- Keep `cargo` and `rustc` out of Homebrew.

## Bootstrap Contract

A new machine should need:

1. Apple Command Line Tools.
2. This repository cloned to `~/dotfiles`.
3. `./setup/bootstrap.sh`.
4. Manual sign-ins and app approvals from `setup/manual-installs.txt`.
5. `just doctor`.

Anything else is drift and should either become explicit here or be removed.
