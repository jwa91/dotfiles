#!/usr/bin/env bash
# Canonical dotfiles bootstrap entrypoint.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

DRY_RUN=false
SKIP_BREW=false
SKIP_LINK=false
RESET_LINKS=false
UPDATE_PLUGINS=false
ALLOW_EMPTY_RUNTIME=false
ONLY_TARGET="all"

# shellcheck source=setup/lib/logging.sh
source "$LIB_DIR/logging.sh"
# shellcheck source=setup/lib/paths.sh
source "$LIB_DIR/paths.sh"
# shellcheck source=setup/lib/runtime.sh
source "$LIB_DIR/runtime.sh"
# shellcheck source=setup/lib/links.sh
source "$LIB_DIR/links.sh"
# shellcheck source=setup/lib/brew.sh
source "$LIB_DIR/brew.sh"
# shellcheck source=setup/lib/zsh.sh
source "$LIB_DIR/zsh.sh"
# shellcheck source=setup/lib/manual.sh
source "$LIB_DIR/manual.sh"
# shellcheck source=setup/lib/doctor.sh
source "$LIB_DIR/doctor.sh"

usage() {
    cat <<'EOF'
Usage: ./setup/bootstrap.sh [options]

Options:
  --dry-run              Print actions without changing files
  --no-brew              Skip Homebrew and non-Homebrew installs
  --no-link              Skip config linking
  --reset                Remove managed symlinks before linking
  --update               Update zsh plugins with git pull --ff-only
  --only <target>        Run one target: all, brew, standalone, zsh, manual, runtime, links, doctor
  --check                Alias for --only doctor
  --allow-empty-runtime  Create empty runtime files when a seed example is missing
  -h, --help             Show this help
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                ;;
            --no-brew)
                SKIP_BREW=true
                ;;
            --no-link)
                SKIP_LINK=true
                ;;
            --reset)
                RESET_LINKS=true
                ;;
            --update)
                UPDATE_PLUGINS=true
                ;;
            --only)
                if [[ $# -lt 2 ]]; then
                    log_error "--only requires a target"
                    usage
                    exit 1
                fi
                ONLY_TARGET="$2"
                shift
                ;;
            --check)
                ONLY_TARGET="doctor"
                ;;
            --allow-empty-runtime)
                ALLOW_EMPTY_RUNTIME=true
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option '$1'"
                usage
                exit 1
                ;;
        esac
        shift
    done
}

run_target() {
    case "$ONLY_TARGET" in
        all)
            preflight
            ensure_tooling_prerequisites
            install_brew_bundle
            install_standalone_tools
            setup_zsh_environment
            print_manual_install_checklist
            link_configs
            ;;
        brew)
            preflight
            ensure_tooling_prerequisites
            install_brew_bundle
            ;;
        standalone)
            preflight
            install_standalone_tools
            ;;
        zsh)
            preflight
            setup_zsh_environment
            ;;
        manual)
            print_manual_install_checklist
            ;;
        runtime)
            preflight
            ensure_runtime_files
            ;;
        links)
            preflight
            link_configs
            ;;
        doctor)
            doctor
            ;;
        *)
            log_error "Unknown --only target '$ONLY_TARGET'"
            usage
            exit 1
            ;;
    esac
}

main() {
    parse_args "$@"

    if $DRY_RUN; then
        log_section "Dry Run Mode"
        log_skip "No changes will be made"
    fi

    run_target

    log_section "Complete"
    log_skip "Bootstrap target '$ONLY_TARGET' finished"
}

main "$@"
