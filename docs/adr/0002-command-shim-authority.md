# ADR 0002: Command Shim Authority

## Status

Accepted

## Context

`mise activate zsh` intentionally prepends active project tool directories to `PATH`. That is correct for runtime selection, but it can bypass this repo's guard shims for commands such as `node`, `npm`, `pnpm`, `python`, and `pip`.

## Decision

Dotfiles shims are the command authority. Interactive zsh re-prepends `~/.local/bin` after mise activation so policy shims stay first on `PATH`. Those shims still use mise or uv to resolve the actual runtime.

## Consequences

There is one visible command surface for humans, scripts, and agents. Runtime selection still belongs to mise and uv, but mutation policy belongs to these dotfiles. This is intentionally stricter than vanilla mise shell activation, so `just doctor` verifies interactive zsh shim precedence.
