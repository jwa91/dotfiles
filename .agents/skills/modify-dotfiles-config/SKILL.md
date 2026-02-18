---
name: modify-dotfiles-config
description: Safely modify app config and setup/linking behavior in this repository. Use when changes affect files under config/, Brew package intent, symlink targets, or bootstrap runtime initialization.
---

# Modify Dotfiles Config

## Scope
- `config/**`
- `Brewfile`
- `setup/bootstrap.sh` for app-linking and runtime config behavior

## Workflow
1. Read affected config files and the relevant bootstrap sections before editing.
2. Apply minimal edits while preserving deterministic setup/link behavior.
3. Validate syntax, dry-run behavior, and package/config intent.

## Guardrails
- Keep secret-bearing runtime files outside tracked templates.
- Fail fast on unsafe target conflicts.
- Preserve deterministic linking paths and bootstrap order.
- If Python tooling is needed, use `uv run --with ...` instead of global `pip install`.

## Validation
- Run `bash -n setup/bootstrap.sh`.
- Run `./setup/bootstrap.sh --dry-run`.
- Run `brew bundle check --file Brewfile` when `Brewfile` changes.
- Confirm changed paths and runtime initialization notes in summary.
