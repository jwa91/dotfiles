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

## Naming Conventions
All aliases and functions use: **action prefix + shortest target, mashed** (no hyphens/underscores). Private helpers start with `_`.

| Prefix | Action | Examples |
|--------|--------|----------|
| `mk` | make/create | `mkpass`, `mkroute`, `mkskill` |
| `e` | edit/open | `ezsh`, `edots`, `evault`, `edev` |
| `cd` | navigate | `cdd`, `cdzsh`, `cddots`, `cdvault` |
| `t` | tmux | `tmain`, `tls`, `tpick` |
| `cw` | claude worktree | `cw`, `cwls`, `cwrm`, `cwprune` |
| `py` | python | `pyclean` |

When `e` and `cd` target the same directory, both variants must exist. Standalone names (no prefix) are allowed when the name is already unambiguous (`reload`, `key`, `rwe`).

## Guardrails
- Follow the naming conventions above when adding or renaming aliases/functions.
- Preserve secret hygiene (never add credentials).
- Keep bootstrap behavior deterministic and non-destructive.
- Prefer minimal edits and clear comments only where needed.
- If Python tooling is needed, use `uv run --with ...` instead of global `pip install`.

## Cheat Sheets
When aliases or functions are added, renamed, or removed, update the personal cheat sheet at `config/cheat/cheatsheets/zsh` to stay in sync. Follow the existing format: `name` left-aligned with `# description` comment.

## Validation
- Run `zsh -n` on changed zsh files.
- Run `bash -n setup/bootstrap.sh` if zsh flow in bootstrap changed.
- Summarize user-visible shell behavior changes.
