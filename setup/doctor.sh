#!/usr/bin/env bash
# Inspect managed workstation state without changing it.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

ALLOW_EMPTY_LOCAL_CONFIG=false
TARGET="all"

# shellcheck source=setup/lib/logging.sh
source "$LIB_DIR/logging.sh"
# shellcheck source=setup/lib/paths.sh
source "$LIB_DIR/paths.sh"
# shellcheck source=setup/lib/manifest.sh
source "$LIB_DIR/manifest.sh"
# shellcheck source=setup/doctor/system.sh
source "$SCRIPT_DIR/doctor/system.sh"
# shellcheck source=setup/doctor/homebrew.sh
source "$SCRIPT_DIR/doctor/homebrew.sh"
# shellcheck source=setup/doctor/runtimes.sh
source "$SCRIPT_DIR/doctor/runtimes.sh"
# shellcheck source=setup/doctor/shell.sh
source "$SCRIPT_DIR/doctor/shell.sh"
# shellcheck source=setup/doctor/links.sh
source "$SCRIPT_DIR/doctor/links.sh"
# shellcheck source=setup/doctor/applications.sh
source "$SCRIPT_DIR/doctor/applications.sh"
# shellcheck source=setup/doctor/projects.sh
source "$SCRIPT_DIR/doctor/projects.sh"

usage() {
    cat <<'EOF'
Usage: ./setup/doctor.sh [target] [options]

Targets:
  all             Inspect every managed domain (default)
  system          Inspect required commands, directories, and SSH agent state
  homebrew        Inspect Homebrew policy and Brewfile state
  runtimes        Inspect runtime ownership and toolchain state
  shell           Inspect interactive Zsh and prompt state
  links           Inspect managed configuration and command links
  applications    Inspect managed application integrations
  projects        Audit project runtime ownership

Options:
  --allow-empty-local-config      Allow an empty local config when no seed exists
  -h, --help                      Show this help
EOF
}

parse_args() {
    local target_set=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            all|system|homebrew|runtimes|shell|links|applications|projects)
                if $target_set; then
                    log_error "Only one doctor target may be selected"
                    usage
                    exit 1
                fi
                TARGET="$1"
                target_set=true
                ;;
            --allow-empty-local-config)
                ALLOW_EMPTY_LOCAL_CONFIG=true
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown doctor argument '$1'"
                usage
                exit 1
                ;;
        esac
        shift
    done
}

run_target() {
    local failed=0

    case "$TARGET" in
        all)
            doctor_system || failed=1
            doctor_homebrew || failed=1
            doctor_runtimes || failed=1
            doctor_shell || failed=1
            doctor_links || failed=1
            doctor_applications || failed=1
            doctor_projects || failed=1
            ;;
        system)
            doctor_system || failed=1
            ;;
        homebrew)
            doctor_homebrew || failed=1
            ;;
        runtimes)
            doctor_runtimes || failed=1
            ;;
        shell)
            doctor_shell || failed=1
            ;;
        links)
            doctor_links || failed=1
            ;;
        applications)
            doctor_applications || failed=1
            ;;
        projects)
            doctor_projects || failed=1
            ;;
    esac

    return "$failed"
}

main() {
    parse_args "$@"
    setup_path
    preflight

    log_section "Doctor"
    if run_target; then
        log_skip "Doctor target '$TARGET' passed"
    else
        log_error "Doctor target '$TARGET' found issues"
        exit 1
    fi
}

main "$@"
