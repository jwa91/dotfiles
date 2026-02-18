---
name: understand-dotfiles
description: Analyze this dotfiles repository and explain setup flow, symlink behavior, package sources, and likely failure points. Use when asked to understand, audit, debug, or summarize how these dotfiles work.
---

# Understand Dotfiles

## Use This Skill When
- The user asks how setup works end-to-end.
- The user asks why a linked config is not applied.
- The user asks for a high-level or file-by-file architecture overview.
- The user asks for risk/impact before changing dotfiles.

## Workflow
1. Read `README.md`, `CHANGELOG.md`, `Brewfile`, and `setup/bootstrap.sh` first.
2. Map config ownership across `zsh/`, `git/`, and `config/`.
3. Identify secret-bearing runtime paths versus tracked templates.
4. Summarize behavior, then list concrete checks/commands.

## Output Format
- Current setup model
- Key files and responsibilities
- Risk points and conflict paths
- Recommended next checks
