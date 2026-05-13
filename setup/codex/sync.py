#!/usr/bin/env python3
# Pure stdlib — works on Apple's bundled /usr/bin/python3 (3.9+).
"""Codex config helper.

Splits ~/.codex/config.toml into a versionable "base" portion and a
machine-local "runtime" portion that Codex writes itself (trust prompts,
plugin/marketplace caches, dismissed notices, etc) or that we intentionally
keep project-local (per-project tuning knobs).

The lists below are the single source of truth for what counts as runtime
state — runtime section headers (`[header]`) and runtime top-level keys
(pre-header `key = value` lines). Callers:
  • setup/codex/sync.sh (reinstall): `compose <base> <live>`
  • setup/hooks/codex-config-drift.sh (drift detector): `strip-runtime <file>`

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
    "hooks.state.",
)

# Top-level [projects."/"] is the universal trust mark, not a per-machine
# absolute path — keep it in base. Any other [projects."..."] is machine-local.
RUNTIME_EXCEPTIONS: frozenset[str] = frozenset({'projects."/"'})

# Top-level keys (outside any section header) treated as machine-local.
# Reasoning-effort knobs are tuned per project, not unified at the dotfiles
# level, so they should not trigger drift.
RUNTIME_KEYS: frozenset[str] = frozenset(
    {"model_reasoning_effort", "plan_mode_reasoning_effort"}
)

HEADER_RE = re.compile(r'^\s*\[\[?([^\]]+)\]?\]\s*(?:#.*)?$')
KEY_RE = re.compile(r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=')


def is_runtime_header(name: str) -> bool:
    name = name.strip()
    if name in RUNTIME_EXCEPTIONS:
        return False
    for prefix in RUNTIME_PREFIXES:
        if prefix.endswith("."):
            # Match both subkeys (`prefix.subkey`) and the bare table (`prefix`
            # without trailing dot) — Codex writes `[tui.model_availability_nux]`
            # as a plain table, not under a subkey.
            if name.startswith(prefix) or name == prefix[:-1]:
                return True
        elif name == prefix:
            return True
    return False


def split_runtime(text: str) -> tuple[str, str, str]:
    """Return (base, runtime_keys, runtime_sections) preserving formatting.

    - base: pre-header non-runtime lines + non-runtime section bodies.
    - runtime_keys: pre-header `key = value` lines whose key is in RUNTIME_KEYS.
    - runtime_sections: runtime `[header]` blocks with their bodies.
    """
    base: list[str] = []
    runtime_keys: list[str] = []
    runtime_sections: list[str] = []
    seen_header = False
    in_runtime_section = False
    for line in text.splitlines(keepends=True):
        header_match = HEADER_RE.match(line)
        if header_match:
            seen_header = True
            in_runtime_section = is_runtime_header(header_match.group(1))
            (runtime_sections if in_runtime_section else base).append(line)
            continue
        if not seen_header:
            key_match = KEY_RE.match(line)
            if key_match and key_match.group(1) in RUNTIME_KEYS:
                runtime_keys.append(line)
                continue
            base.append(line)
        else:
            (runtime_sections if in_runtime_section else base).append(line)
    base_str = "".join(base)
    while base_str.endswith("\n\n"):
        base_str = base_str[:-1]
    return base_str, "".join(runtime_keys), "".join(runtime_sections)


def compose(base_text: str, live_text: str) -> str:
    """Merge base file with runtime keys + sections extracted from live file.

    Runtime keys are inserted into the base's pre-header region (before the
    first `[section]`), preserving TOML semantics. Runtime sections are
    appended at the end.
    """
    _, runtime_keys, runtime_sections = split_runtime(live_text)

    if runtime_keys:
        lines = base_text.splitlines(keepends=True)
        insert_at = len(lines)
        for i, line in enumerate(lines):
            if HEADER_RE.match(line):
                insert_at = i
                break
        # Strip trailing blank lines from the pre-header region so the inserted
        # keys sit flush with the existing top-level keys.
        while insert_at > 0 and lines[insert_at - 1].strip() == "":
            insert_at -= 1
        merged_base = "".join(lines[:insert_at]) + runtime_keys + "".join(lines[insert_at:])
    else:
        merged_base = base_text

    if not runtime_sections:
        return merged_base

    sep = "" if merged_base.endswith("\n\n") else ("\n" if merged_base.endswith("\n") else "\n\n")
    return merged_base + sep + runtime_sections


def main() -> int:
    args = sys.argv[1:]
    if not args:
        print(
            "usage: sync.py {strip-runtime <file>|compose <base> <live>}",
            file=sys.stderr,
        )
        return 2
    cmd = args[0]
    try:
        if cmd == "strip-runtime":
            if len(args) != 2:
                print("usage: sync.py strip-runtime <file>", file=sys.stderr)
                return 2
            with open(args[1], encoding="utf-8") as f:
                text = f.read()
            base, _, _ = split_runtime(text)
            sys.stdout.write(base)
            return 0
        if cmd == "compose":
            if len(args) != 3:
                print("usage: sync.py compose <base> <live>", file=sys.stderr)
                return 2
            with open(args[1], encoding="utf-8") as f:
                base_text = f.read()
            try:
                with open(args[2], encoding="utf-8") as f:
                    live_text = f.read()
            except FileNotFoundError:
                live_text = ""
            sys.stdout.write(compose(base_text, live_text))
            return 0
    except FileNotFoundError as exc:
        print(f"file not found: {exc.filename}", file=sys.stderr)
        return 1
    print(f"unknown command: {cmd}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
