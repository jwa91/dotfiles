#!/usr/bin/env bash
# ----------------------------------------
# File: setup/codex/sync.sh
# Description: Install/refresh ~/.codex/config.toml from the dotfiles base,
#              preserving any machine-local sections Codex has written.
# Usage: ./setup/codex/sync.sh [--dry-run]
# ----------------------------------------
#
# Codex rewrites ~/.codex/config.toml at runtime (trust prompts, plugin
# enables, marketplace cache timestamps with absolute paths). Symlinking
# into dotfiles therefore pollutes the repo. This script keeps:
#
#   ~/.codex/config.toml            (real file, machine-local)
#         = base (from dotfiles) + runtime sections (preserved from current live)
#
#   config/codex/config.toml        (versioned base)
#
# Drift between the two is caught by setup/hooks/codex-config-drift.sh.

set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BASE_FILE="$DOTFILES_DIR/config/codex/config.toml"
LIVE_FILE="$HOME/.codex/config.toml"
PYTHON_BIN="${PYTHON_BIN:-/usr/bin/python3}"
SPLITTER="$SCRIPT_DIR/sync.py"

if [[ ! -f "$BASE_FILE" ]]; then
    echo "✗ Base config not found at $BASE_FILE" >&2
    exit 1
fi
if [[ ! -x "$PYTHON_BIN" ]]; then
    echo "✗ Python not found at $PYTHON_BIN (set PYTHON_BIN to override)" >&2
    exit 1
fi

mkdir -p "$(dirname "$LIVE_FILE")"

# Compose merged output (base + runtime keys/sections preserved from live)
# BEFORE breaking any legacy symlink — if the symlink points at the dotfiles
# base, removing it would lose these.
TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT
if [[ -e "$LIVE_FILE" ]]; then
    "$PYTHON_BIN" "$SPLITTER" compose "$BASE_FILE" "$LIVE_FILE" >"$TMP_FILE"
else
    cat "$BASE_FILE" >"$TMP_FILE"
fi

# If live file is currently a symlink (legacy bootstrap), break it.
if [[ -L "$LIVE_FILE" ]]; then
    echo "→ Removing legacy symlink at $LIVE_FILE"
    if ! $DRY_RUN; then
        rm "$LIVE_FILE"
    fi
fi

RUNTIME_SECTION_COUNT=$(grep -c '^\[' "$TMP_FILE" 2>/dev/null || true)
BASE_SECTION_COUNT=$(grep -c '^\[' "$BASE_FILE" 2>/dev/null || true)
RUNTIME_SECTIONS=$(( RUNTIME_SECTION_COUNT - BASE_SECTION_COUNT ))

if [[ -f "$LIVE_FILE" ]] && cmp -s "$TMP_FILE" "$LIVE_FILE"; then
    echo "✓ $LIVE_FILE already in sync"
    exit 0
fi

if $DRY_RUN; then
    echo "○ WOULD: write $LIVE_FILE (base + ${RUNTIME_SECTIONS} runtime sections)"
    exit 0
fi

mv "$TMP_FILE" "$LIVE_FILE"
trap - EXIT
echo "→ Wrote $LIVE_FILE (base + ${RUNTIME_SECTIONS} preserved runtime sections)"
