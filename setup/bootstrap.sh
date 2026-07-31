#!/usr/bin/env bash
# Dependency-free new-machine entrypoint: initialize capabilities, then set managed configuration.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=false
RESET_LINKS=false
UPDATE_PLUGINS=false
ALLOW_EMPTY_LOCAL_CONFIG=false

usage() {
    cat <<'EOF'
Usage: ./setup/bootstrap.sh [options]

Options:
  --dry-run                       Print actions without changing files
  --reset-links                   Remove managed links before recreating them
  --update-plugins                Update existing Zsh plugin checkouts
  --allow-empty-local-config      Allow an empty local config when no seed exists
  -h, --help                      Show this help
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                ;;
            --reset-links)
                RESET_LINKS=true
                ;;
            --update-plugins)
                UPDATE_PLUGINS=true
                ;;
            --allow-empty-local-config)
                ALLOW_EMPTY_LOCAL_CONFIG=true
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                printf "bootstrap: unknown option '%s'\n" "$1" >&2
                usage
                exit 1
                ;;
        esac
        shift
    done
}

main() {
    parse_args "$@"

    local init_args=(all)
    local set_args=(all)

    if $DRY_RUN; then
        init_args+=(--dry-run)
        set_args+=(--dry-run)
    fi

    if $UPDATE_PLUGINS; then
        init_args+=(--update-plugins)
    fi

    if $RESET_LINKS; then
        set_args+=(--reset-links)
    fi

    if $ALLOW_EMPTY_LOCAL_CONFIG; then
        set_args+=(--allow-empty-local-config)
    fi

    DOTFILES_SETUP_NESTED=1 "$SCRIPT_DIR/init.sh" "${init_args[@]}"
    DOTFILES_SETUP_NESTED=1 "$SCRIPT_DIR/set.sh" "${set_args[@]}"
    DOTFILES_SETUP_NESTED=1 "$SCRIPT_DIR/init.sh" manual

    printf '\nBootstrap complete.\n'
}

main "$@"
