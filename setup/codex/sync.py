#!/usr/bin/env python3
# Pure stdlib — works on Apple's bundled /usr/bin/python3 (3.9+).
"""Codex config helper.

Splits ~/.codex/config.toml into a versionable "base" portion and a
machine-local "runtime" portion that Codex writes itself (trust prompts,
plugin/marketplace caches, dismissed notices, etc).

The list below is the single source of truth for what counts as runtime
state. Both setup/codex/sync.sh (reinstall) and
setup/hooks/codex-config-drift.sh (pre-commit drift detector) call this
script with `extract-runtime` or `strip-runtime`.

This intentionally works at the text level — no TOML parser dependency —
because the runtime tables Codex writes are always standard `[header]`
form, never inline tables.
"""

from __future__ import annotations

import re
import sys

# Section header prefixes (or exact names) considered runtime / machine-local.
# A trailing dot means "any subkey path under this prefix matches".
RUNTIME_PREFIXES: tuple[str, ...] = (
    "projects.",
    "notice",
    "notice.",
    "marketplaces.",
    "plugins.",
    "tui.model_availability_nux.",
)

# Top-level [projects."/"] is the universal trust mark, not a per-machine
# absolute path — keep it in base. Any other [projects."..."] is machine-local.
RUNTIME_EXCEPTIONS: frozenset[str] = frozenset({'projects."/"'})

HEADER_RE = re.compile(r'^\s*\[\[?([^\]]+)\]?\]\s*(?:#.*)?$')


def is_runtime_header(name: str) -> bool:
    name = name.strip()
    if name in RUNTIME_EXCEPTIONS:
        return False
    for prefix in RUNTIME_PREFIXES:
        if prefix.endswith("."):
            if name.startswith(prefix):
                return True
        elif name == prefix:
            return True
    return False


def split_runtime(text: str) -> tuple[str, str]:
    """Return (base_text, runtime_text) preserving original formatting."""
    base: list[str] = []
    runtime: list[str] = []
    target = base  # Pre-header (top-level keys) goes to base.
    for line in text.splitlines(keepends=True):
        match = HEADER_RE.match(line)
        if match:
            target = runtime if is_runtime_header(match.group(1)) else base
        target.append(line)
    return "".join(base), "".join(runtime)


def main() -> int:
    if len(sys.argv) != 3:
        print(
            "usage: sync.py {extract-runtime|strip-runtime} <file>",
            file=sys.stderr,
        )
        return 2
    cmd, path = sys.argv[1], sys.argv[2]
    try:
        with open(path, encoding="utf-8") as f:
            text = f.read()
    except FileNotFoundError:
        return 0
    base, runtime = split_runtime(text)
    if cmd == "extract-runtime":
        sys.stdout.write(runtime)
    elif cmd == "strip-runtime":
        sys.stdout.write(base)
    else:
        print(f"unknown command: {cmd}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
