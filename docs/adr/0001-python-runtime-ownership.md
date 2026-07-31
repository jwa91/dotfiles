# ADR 0001: Python Runtime Ownership

## Status

Accepted

## Context

Python command lookup is ambiguous by default: system/framework Python, virtualenvs, Homebrew packages, and agents can all provide or invoke it. This repo needs a small host runtime surface and a clear answer to "what runs this code?"

## Decision

Python is owned by uv.

`UV_MANAGED_PYTHON=1` is exported globally. Bare `python`, `python3`, `pip`, and `pip3` are guard shim commands, not resolvers. Project code runs with `uv run`; project dependencies use `uv add` and `uv.lock`; one-off script dependencies use `uv run --with`; one-off Python CLIs use `uvx`; durable personal CLIs use `uv tool install`. `uv pip ...` is only for explicit legacy/manual virtualenv work.

## Consequences

Agents and scripts cannot silently fall through to system/framework Python, but third-party `#!/usr/bin/env python3` scripts may need uv or an explicit interpreter path. uv may download managed Python runtimes on demand; `UV_PYTHON_DOWNLOADS=never` is intentionally not the default.

`just doctor` fails if `UV_MANAGED_PYTHON` is not `1` or bare Python/pip commands resolve outside the dotfiles shims.
