# CLI Boundary and Local Layout

This document defines where logic belongs and how local repos are organized on this machine.

## Ownership Boundary

- **Dotfiles owns**
  - Shell UX and navigation (`zsh/*`)
  - Machine bootstrap/linking (`setup/bootstrap.sh`)
  - Install intent (`Brewfile`)
  - Security policy references (`docs/security-ground-rules.md`)
- **`jwa-*` and related CLIs own**
  - Build/release/sign/notarize logic (`.goreleaser.yaml`, `scripts/*`, workflow gates)
  - Project-level doctor/align/init behavior
  - Tap publishing mechanics (through each source repo pipeline)
- **`homebrew-tap` owns**
  - Distribution artifacts (`Casks/*.rb`, exceptional `Formula/*.rb`)
  - Tap-level ADR/docs only

Rule of thumb:
- Keep it in dotfiles if it is shell ergonomics or machine-local setup glue.
- Move it into a Go CLI if it defines portable repo automation behavior.

## Local Repository Root

`DEV_DIR` is the canonical root for local code checkouts.

Resolution:
- Prefer `~/developer` when it exists.
- Fallback to `~/Developer`.

## Current Family Layout (This Machine)

- `~/developer/homebrew-tap`
- `~/developer/jwa-harden`
- `~/developer/jwa-tobrew`
- `~/developer/ai-monorepo/agentskills`
- `~/developer/rsvg/prehandover`
- `~/developer/vps` and `~/developer/vps/services/*`

`mkskill` prefers the local `agentskills` checkout at
`$DEV_DIR/ai-monorepo/agentskills`, then falls back to the public repo URL.

## Portability Rules

- Public CLIs/casks must not depend on machine-specific absolute paths.
- Dotfiles may define local defaults (`DEV_DIR`), but CLIs should rely on
  arguments/env/config and remain portable.
- Secrets stay in 1Password and are injected at runtime (`op run`), never
  stored in tracked files.
