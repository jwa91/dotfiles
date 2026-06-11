# dotfiles

Configuration and machine setup for two Apple Silicon Macs (personal + work),
kept intentionally identical: **a tool exists on both machines or on neither.**

## The one rule

**Everything installs via the [Brewfile](Brewfile).** Exceptions are
enumerated, never derived:

| Where | What | Why |
|---|---|---|
| [Brewfile](Brewfile) | All host software brew can deliver — CLI and GUI alike | One manifest, one update channel, ecosystem-maintained |
| [setup/lib/brew.sh](setup/lib/brew.sh) (runs in bootstrap) | claude code, codex, amp | Fast-moving agent CLIs; first-party installers self-update same-day |
| [setup/manual-installs.txt](setup/manual-installs.txt) | Xcode, Tailscale, 1Password, Google Drive, Docker, go, rustup | Need a human (App Store, passwords, biometrics) or are on-demand toolchains |

GUI casks are bootstrap-only installs: every app self-updates through its own
channel afterwards. `brew upgrade` skips them by design — never pass `--greedy`.

## Layers

1. **Shell & config** — this repo; `./setup/bootstrap.sh` links everything.
2. **Host software** — the rule above.
3. **Project runtimes** — never global: uv (Python), mise (node/pnpm/bun,
   per-project pins only), the go toolchain directive, rustup. Outside a
   project, `node` and `python` deliberately don't resolve — this keeps both
   humans and coding agents from installing globally without a discussion.
   [config/claude-code/settings.json](config/claude-code/settings.json)
   additionally denies global-install commands outright.
4. **Project dependencies** — lockfiles inside each repo, nowhere else.

## A new machine, day 1

1. `xcode-select --install` — interactive GUI prompt; git needs it
2. `git clone https://github.com/jwa91/dotfiles ~/dotfiles` — HTTPS, no keys yet
3. `./setup/bootstrap.sh` — Homebrew, Brewfile, agent CLIs, links, zsh
4. Install 1Password from the checklist, sign in, enable its SSH agent
5. Switch the git remote to SSH; work through the rest of the checklist
6. `./setup/doctor.sh` until green

## Staying aligned

- `brewsync` — installs anything missing from the Brewfile, then dry-run
  lists strays (removal is always a deliberate manual step)
- `./setup/doctor.sh` — drift and runtime-leak detector; fails if a global
  python/node sneaks onto the host
- Apps update themselves; `brew upgrade` covers the CLI layer
