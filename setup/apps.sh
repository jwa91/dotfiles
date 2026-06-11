#!/usr/bin/env bash
# ----------------------------------------
# GUI apps — installed straight from each vendor's official channel.
# Homebrew never touches anything with a UI: the Brewfile owns the
# terminal, this catalog owns desktop apps. Every app here self-updates
# after the first install (hiddenbar excepted — rerun this to update it).
#
# Usage:
#   ./setup/apps.sh             install the full catalog
#   ./setup/apps.sh stats ...   install a subset
#   ./setup/apps.sh --list      print the catalog
#   ./setup/apps.sh --dry-run   resolve download URLs, install nothing
#
# Migrating an app that Homebrew installed earlier (settings live in
# ~/Library and survive):
#   brew uninstall --cask <cask-name> && ./setup/apps.sh <key>
#
# Sources: a plain vendor URL where the vendor publishes a stable one,
# the latest GitHub release asset otherwise. arm64 artifacts are
# hardcoded — every machine in this setup is Apple Silicon.
# ----------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=setup/lib/logging.sh
source "$SCRIPT_DIR/lib/logging.sh"

log_done() { echo -e "${GREEN}DONE:${NC} $1"; }

APPS=(
    raycast
    hiddenbar
    chrome-dev
    helium
    obsidian
    spotify
    stats
    telegram
    whatsapp
    claude
    cursor
    docker
    codexbar
    proton-pass
)

app_bundle() {
    case "$1" in
        raycast)     echo "Raycast" ;;
        hiddenbar)   echo "Hidden Bar" ;;
        chrome-dev)  echo "Google Chrome Dev" ;;
        helium)      echo "Helium" ;;
        obsidian)    echo "Obsidian" ;;
        spotify)     echo "Spotify" ;;
        stats)       echo "Stats" ;;
        telegram)    echo "Telegram" ;;
        whatsapp)    echo "WhatsApp" ;;
        claude)      echo "Claude" ;;
        cursor)      echo "Cursor" ;;
        docker)      echo "Docker" ;;
        codexbar)    echo "CodexBar" ;;
        proton-pass) echo "Proton Pass" ;;
        *)           return 1 ;;
    esac
}

github_latest_asset() {
    curl -fsSL "https://api.github.com/repos/$1/releases/latest" |
        jq -er --arg re "$2" '[.assets[] | select(.name | test($re))][0].browser_download_url'
}

app_url() {
    case "$1" in
        raycast)     echo "https://api.raycast.com/v2/download" ;;
        hiddenbar)   github_latest_asset "dwarvesf/hidden" '\.zip$' ;;
        chrome-dev)  echo "https://dl.google.com/chrome/mac/universal/dev/googlechromedev.dmg" ;;
        helium)      github_latest_asset "imputnet/helium-macos" 'arm64-macos\.dmg$' ;;
        obsidian)    github_latest_asset "obsidianmd/obsidian-releases" '^Obsidian-[0-9.]+\.dmg$' ;;
        spotify)     echo "https://download.scdn.co/SpotifyARM64.dmg" ;;
        stats)       github_latest_asset "exelban/stats" '^Stats\.dmg$' ;;
        telegram)    echo "https://osx.telegram.org/updates/Telegram.dmg" ;;
        whatsapp)    echo "https://web.whatsapp.com/desktop/mac_native/release/?configuration=Release" ;;
        claude)      echo "https://storage.googleapis.com/osprey-downloads-c02f6a0d-347c-492b-a752-3e0651722e97/nest/Claude.dmg" ;;
        cursor)      curl -fsSL "https://cursor.com/api/download?platform=darwin-universal&releaseTrack=stable" | jq -er '.downloadUrl' ;;
        docker)      echo "https://desktop.docker.com/mac/main/arm64/Docker.dmg" ;;
        codexbar)    github_latest_asset "steipete/CodexBar" '^CodexBar-macos-universal-[0-9.]+\.zip$' ;;
        proton-pass) echo "https://proton.me/download/PassDesktop/darwin/universal/ProtonPass.dmg" ;;
        *)           return 1 ;;
    esac
}

# Copies the .app out of a downloaded payload (dmg or zip) into /Applications.
install_payload() {
    local payload="$1" workdir="$2"
    local app_path mount

    if printf 'Y\n' | hdiutil attach -nobrowse -readonly -noautoopen "$payload" > "$workdir/mount.txt" 2>/dev/null; then
        mount="$(awk -F'\t' '/\/Volumes\//{print $NF; exit}' "$workdir/mount.txt")"
        app_path="$(find "$mount" -maxdepth 1 -name '*.app' -print -quit)"
        if [[ -z "$app_path" ]]; then
            hdiutil detach "$mount" -quiet
            return 1
        fi
        ditto "$app_path" "/Applications/$(basename "$app_path")"
        hdiutil detach "$mount" -quiet
        return 0
    fi

    if [[ "$(head -c 2 "$payload" 2>/dev/null)" == "PK" ]]; then
        ditto -xk "$payload" "$workdir/extract"
        app_path="$(find "$workdir/extract" -maxdepth 2 -name '*.app' -print -quit)"
        [[ -n "$app_path" ]] || return 1
        ditto "$app_path" "/Applications/$(basename "$app_path")"
        return 0
    fi

    return 1
}

install_app() {
    local key="$1" bundle url workdir

    if ! bundle="$(app_bundle "$key")"; then
        log_error "Unknown app: $key (see ./setup/apps.sh --list)"
        return 1
    fi

    if [[ -d "/Applications/$bundle.app" ]]; then
        log_skip "$bundle.app"
        return 0
    fi

    if ! url="$(app_url "$key")"; then
        log_error "$key: could not resolve download URL"
        return 1
    fi

    log_action "Install $bundle.app from $url"
    if $DRY_RUN; then
        return 0
    fi

    workdir="$(mktemp -d)"
    if curl -fsSL --retry 2 --connect-timeout 20 -o "$workdir/payload" "$url" \
        && install_payload "$workdir/payload" "$workdir"; then
        rm -rf "$workdir"
        log_done "$bundle.app"
        return 0
    fi

    rm -rf "$workdir"
    log_error "$key: install failed"
    return 1
}

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

failed=0
log_section "GUI Apps"
for app in "${targets[@]}"; do
    install_app "$app" || failed=1
done

exit "$failed"
