#!/usr/bin/env bash
# ----------------------------------------
# GUI apps installer — everything with its own UI lives here.
# The Brewfile owns the terminal layer; this catalog owns desktop apps.
# Which apps a machine gets is decided by running this, not by profiles.
#
# Usage:
#   ./setup/apps.sh             install the full catalog
#   ./setup/apps.sh stats ...   install a subset
#   ./setup/apps.sh --list      print the catalog
#   ./setup/apps.sh --dry-run   show what would happen
#
# All apps install as brew casks today: each cask ships the vendor's own
# artifact, and the apps self-update on macOS (auto_updates casks), so cask
# version lag doesn't apply (verified 2026-06). Exception: hiddenbar has no
# self-updater — brew upgrade is its update path. To move an app to another
# channel, give it its own branch in install_app.
# ----------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=setup/lib/logging.sh
source "$SCRIPT_DIR/lib/logging.sh"

APPS=(
    raycast
    hiddenbar
    google-chrome@dev
    helium-browser
    obsidian
    spotify
    stats
    telegram
    whatsapp
)

DRY_RUN=false
targets=()

for arg in "$@"; do
    case "$arg" in
        --list)
            printf '%s\n' "${APPS[@]}"
            exit 0
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        -*)
            log_error "Unknown flag: $arg"
            exit 2
            ;;
        *)
            targets+=("$arg")
            ;;
    esac
done

if [[ ${#targets[@]} -eq 0 ]]; then
    targets=("${APPS[@]}")
fi

install_app() {
    local app="$1"

    if brew list --cask "$app" >/dev/null 2>&1; then
        log_skip "$app"
        return
    fi

    log_action "Install $app"
    run_cmd brew install --cask "$app"
}

log_section "GUI Apps"
for app in "${targets[@]}"; do
    install_app "$app"
done
