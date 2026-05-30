---
name: understand-dotfiles
description: Analyze this dotfiles repository and explain setup flow, symlink behavior, package sources, and failure points. Use when auditing behavior, debugging setup/linking issues, planning refactors, or comparing machine state against repository intent.
---

# Understand Dotfiles

## Workflow
1. Read `README.md`, `CHANGELOG.md`, `Brewfile`, and `setup/bootstrap.sh` first.
2. Map ownership across `setup/`, `zsh/`, `git/`, and `config/`.
3. Check package intent vs machine state (`brew bundle list --all --file Brewfile`, `brew leaves`, `brew list --cask`).
4. Identify secret-bearing runtime paths versus tracked templates.
5. Summarize behavior and list concrete verification/fix commands.

## Output Contract
- Setup model summary (bootstrap order and conflict behavior)
- Key files and responsibilities
- Drift and risk points
- Recommended next checks and actions

## Guardrails
- Never recommend storing secrets in tracked files.
- Separate active setup from passive reference material: Brew/bootstrap ownership should stay lean, while grab-ready project templates can still belong in the repo.
- Treat GitHub and self-hosted Forgejo as normal git hosts for this machine; non-GitHub taps or remotes are not suspicious by default.
- Prefer deterministic checks and explicit commands.
- If Python tooling is needed, use `uv run --with ...` instead of global `pip install`.
