#!/usr/bin/env bash
# Converge repository-controlled configuration without installing capabilities.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

DRY_RUN=false
RESET_LINKS=false
ALLOW_EMPTY_LOCAL_CONFIG=false
TARGET="all"

# shellcheck source=setup/lib/logging.sh
source "$LIB_DIR/logging.sh"
# shellcheck source=setup/lib/command.sh
source "$LIB_DIR/command.sh"
# shellcheck source=setup/lib/paths.sh
source "$LIB_DIR/paths.sh"
# shellcheck source=setup/lib/manifest.sh
source "$LIB_DIR/manifest.sh"
# shellcheck source=setup/set/local-config.sh
source "$SCRIPT_DIR/set/local-config.sh"
# shellcheck source=setup/set/links.sh
source "$SCRIPT_DIR/set/links.sh"
# shellcheck source=setup/set/default-apps.sh
source "$SCRIPT_DIR/set/default-apps.sh"

usage() {
    cat <<'EOF'
Usage: ./setup/set.sh [target] [options]

Targets:
  all             Converge all managed configuration (default)
  local-config    Seed machine-local configuration files
  links           Converge managed configuration and command links
  default-apps    Apply managed macOS default applications

Options:
  --dry-run                       Print actions without changing files
  --reset-links                   Remove managed links before recreating them
  --allow-empty-local-config      Allow an empty local config when no seed exists
  -h, --help                      Show this help
EOF
}

parse_args() {
    local target_set=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            all|local-config|links|default-apps)
                if $target_set; then
                    log_error "Only one set target may be selected"
                    usage
                    exit 1
                fi
                TARGET="$1"
                target_set=true
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            --reset-links)
                RESET_LINKS=true
                ;;
            --allow-empty-local-config)
                ALLOW_EMPTY_LOCAL_CONFIG=true
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown set argument '$1'"
                usage
                exit 1
                ;;
        esac
        shift
    done
}

run_target() {
    case "$TARGET" in
        all)
            preflight
            link_configs
            apply_default_apps
            ;;
        local-config)
            preflight
            ensure_local_config_files
            ;;
        links)
            preflight
            link_configs
            ;;
        default-apps)
            preflight
            apply_default_apps
            ;;
    esac
}

main() {
    parse_args "$@"
    setup_path

    if $DRY_RUN; then
        log_section "Dry Run Mode"
        log_skip "No changes will be made"
    fi

    run_target

    if [[ "${DOTFILES_SETUP_NESTED:-0}" != "1" ]]; then
        log_section "Complete"
        log_skip "Set target '$TARGET' finished"
    fi
}

main "$@"
