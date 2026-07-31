#!/usr/bin/env bash
# Static repository layout checks.
#
# Deliberately static: no shell is spawned and nothing on the machine is
# inspected. Shell integrity — whether an interactive zsh actually resolves the
# shims, whether plugins loaded — stays in `just doctor`, which can allocate the
# terminal these checks would need. A git hook has no tty, and zsh/plugins.zsh
# returns early without one, so a hook-based interactive check would silently
# exercise a different code path than the one it claims to verify.
#
# Bypass with: SKIP=check-layout git commit

set -uo pipefail

failed=0

fail() {
    echo "x $1"
    failed=1
}

# --- Files sourced by zsh startup must exist --------------------------------
while IFS=: read -r origin _ line; do
    target="${line#*\"}"
    target="${target%\"*}"
    target="${target/\$ZSH_DIR/zsh}"
    target="${target/\$\{ZSH_DIR\}/zsh}"

    [[ "$target" == zsh/* ]] || continue
    [[ -f "$target" ]] || fail "$origin sources a missing file: $target"
done < <(grep -rn '^[[:space:]]*source "\$ZSH_DIR/' zsh/ 2>/dev/null)

# --- Autoloaded functions must exist on fpath -------------------------------
if [[ -f zsh/functions.zsh ]]; then
    while read -r fn; do
        [[ -f "zsh/zsh-functions/$fn" ]] \
            || fail "zsh/functions.zsh autoloads missing function: $fn"
    done < <(sed -n 's/^autoload -Uz //p' zsh/functions.zsh | tr ' ' '\n' | grep -v '^$')
fi

# --- Managed link sources must exist ----------------------------------------
while read -r source_path; do
    resolved="${source_path/\$CONFIG_DIR/config}"
    resolved="${resolved/\$GIT_DIR/git}"
    resolved="${resolved/\$ZSH_DIR/zsh}"

    # Machine-local sources are seeded at setup time, not tracked here.
    [[ "$resolved" == \$DOTFILES_LOCAL_CONFIG_DIR* ]] && continue

    [[ -e "$resolved" ]] || fail "manifest links a missing source: $source_path"
done < <(sed -n 's/^[[:space:]]*"[^|]*|\([^|]*\)|.*$/\1/p' setup/lib/manifest.sh)

# --- Everything in bin/ must be executable with a shebang -------------------
while IFS= read -r script; do
    [[ -x "$script" ]] || fail "not executable: $script"
    read -r first_line < "$script" || first_line=""
    [[ "$first_line" == '#!'* ]] || fail "missing shebang: $script"
done < <(find bin -type f)

if (( failed )); then
    echo "  Layout checks failed. Shell behaviour is checked separately by: just doctor"
    exit 1
fi

echo "✓ Layout checks passed"
