# CLI Boundary and Local Layout

This document defines where logic belongs and how local repos are organized on this machine.

## Ownership Boundary

- **Dotfiles owns**
  - Shell UX and navigation (`zsh/*`)
  - Machine bootstrap/linking (`setup/bootstrap.sh`)
  - Install intent (`Brewfile`)
  - Machine-level ADRs (`docs/adr/*`)
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

Resolution: `~/developer`.

## Current Family Layout (This Machine)

- `~/developer/homebrew-tap`
- `~/developer/jwa-harden`
- `~/developer/agentskills`
- `~/developer/prehandover`
- `~/developer/vps` and `~/developer/vps/services/*`

## Runtime Tooling Policy

Brew is for workstation tools and apps. Language runtimes, language package
managers, formatters, linters, and release tooling belong to projects.

Project lockfiles choose the package manager: `pnpm-lock.yaml` uses `pnpm`,
`package-lock.json` uses `npm`, and `bun.lock` uses `bun`. Python projects
should use project-local `uv` configuration. Prefer ephemeral runners for
one-off commands: `uvx`, `npx`, `pnpm dlx`, `bunx`, or
`go run package@version`.

`mkskill` prefers the local `agentskills` checkout at
`$DEV_DIR/agentskills`, then falls back to the public repo URL.

## Portability Rules

- Public CLIs/casks must not depend on machine-specific absolute paths.
- Dotfiles may define local defaults (`DEV_DIR`), but CLIs should rely on
  arguments/env/config and remain portable.
- Secrets stay in 1Password and are injected at runtime (`op run`), never
  stored in tracked files.
