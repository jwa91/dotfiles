---
name: modify-dotfiles-zsh
description: Safely modify zsh-related dotfiles in this repository, including aliases, functions, plugins, and shell setup behavior. Use when changes touch zsh UX, shell logic, or zsh bootstrap behavior.
---

# Modify Dotfiles Zsh

## Scope
- `zsh/.zshenv`, `zsh/.zshrc`, and `zsh/*.zsh`
- `zsh/zsh-functions/*`
- zsh-relevant sections in `setup/bootstrap.sh`

## Guardrails
- Preserve secret hygiene (never add credentials).
- Keep bootstrap behavior deterministic and non-destructive.
- Prefer minimal edits and clear comments only where needed.

## Validation
- Run `zsh -n` on changed zsh files.
- Run `bash -n setup/bootstrap.sh` if zsh flow in bootstrap changed.
- Summarize user-visible shell behavior changes.
