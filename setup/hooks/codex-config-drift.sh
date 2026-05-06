#!/usr/bin/env bash
# ----------------------------------------
# File: setup/hooks/codex-config-drift.sh
# Description: prek/pre-commit hook that fails when ~/.codex/config.toml has
#              meaningful drift from config/codex/config.toml (the dotfiles
#              base), ignoring machine-local runtime sections that Codex
#              writes itself.
# ----------------------------------------
#
# Bypass with `SKIP=codex-config-drift git commit ...` for one-off commits
# you don't want to fold the drift into.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BASE_FILE="$DOTFILES_DIR/config/codex/config.toml"
LIVE_FILE="$HOME/.codex/config.toml"
PYTHON_BIN="${PYTHON_BIN:-/usr/bin/python3}"
SPLITTER="$DOTFILES_DIR/setup/codex/sync.py"

if [[ ! -f "$LIVE_FILE" ]]; then
    exit 0  # No live config (e.g. fresh machine before first codex run).
fi
if [[ ! -f "$BASE_FILE" ]]; then
    echo "✗ codex-config-drift: base file missing at $BASE_FILE" >&2
    exit 1
fi
if [[ ! -x "$PYTHON_BIN" ]]; then
    exit 0  # Don't block commits on machines without brew python.
fi

LIVE_STRIPPED="$("$PYTHON_BIN" "$SPLITTER" strip-runtime "$LIVE_FILE")"
BASE_CONTENT="$(cat "$BASE_FILE")"

if [[ "$LIVE_STRIPPED" == "$BASE_CONTENT" ]]; then
    exit 0
fi

echo "✗ codex-config-drift: ~/.codex/config.toml has drifted from config/codex/config.toml"
echo ""
echo "Diff (base → live, runtime sections excluded):"
echo "----------------------------------------"
diff -u <(printf '%s' "$BASE_CONTENT") <(printf '%s' "$LIVE_STRIPPED") || true
echo "----------------------------------------"
echo ""
echo "Resolve by either:"
echo "  • Folding intentional changes into config/codex/config.toml, then re-running"
echo "    setup/codex/sync.sh to align the live file."
echo "  • Reverting the live file: setup/codex/sync.sh"
echo "  • Bypassing this commit: SKIP=codex-config-drift git commit ..."
exit 1
