---
name: modify-dotfiles-config
description: Safely modify app config and setup/linking behavior in this repository. Use when changes affect files under config/ or bootstrap linking/runtime initialization.
---

# Modify Dotfiles Config

## Scope
- `config/**`
- `Brewfile`
- `setup/bootstrap.sh` for app-linking and runtime config behavior

## Guardrails
- Keep secret-bearing runtime files outside tracked templates.
- Fail fast on unsafe target conflicts.
- Preserve deterministic linking paths and bootstrap order.

## Validation
- Run `bash -n setup/bootstrap.sh`.
- Run `./setup/bootstrap.sh --dry-run`.
- Confirm changed paths and runtime initialization notes in summary.
