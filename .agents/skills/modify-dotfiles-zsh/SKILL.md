---
name: modify-dotfiles-zsh
description: Safely modify zsh-related dotfiles in this repository, including aliases, functions, plugins, and shell setup behavior. Use when changes touch zsh UX, shell logic, PATH/init behavior, or zsh bootstrap flow.
---

# Modify Dotfiles Zsh

## Scope
- `zsh/.zshenv`, `zsh/.zshrc`, and `zsh/*.zsh`
- `zsh/zsh-functions/*`
- zsh-relevant sections in `setup/bootstrap.sh`

## Workflow
1. Read affected zsh files and `setup/bootstrap.sh` sections before editing.
2. Apply minimal, targeted edits with deterministic behavior.
3. Validate syntax and user-facing behavior.

## Guardrails
- Preserve secret hygiene (never add credentials).
- Keep bootstrap behavior deterministic and non-destructive.
- Prefer minimal edits and clear comments only where needed.
- If Python tooling is needed, use `uv run --with ...` instead of global `pip install`.

## Validation
- Run `zsh -n` on changed zsh files.
- Run `bash -n setup/bootstrap.sh` if zsh flow in bootstrap changed.
- Summarize user-visible shell behavior changes.
