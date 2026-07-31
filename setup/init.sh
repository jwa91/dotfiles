#!/usr/bin/env bash
# Initialize machine capabilities without requiring just or another package manager.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

DRY_RUN=false
UPDATE_PLUGINS=false
TARGET="all"

# shellcheck source=setup/lib/logging.sh
source "$LIB_DIR/logging.sh"
# shellcheck source=setup/lib/command.sh
source "$LIB_DIR/command.sh"
# shellcheck source=setup/lib/paths.sh
source "$LIB_DIR/paths.sh"
# shellcheck source=setup/init/homebrew.sh
source "$SCRIPT_DIR/init/homebrew.sh"
# shellcheck source=setup/init/standalone.sh
source "$SCRIPT_DIR/init/standalone.sh"
# shellcheck source=setup/init/toolchains.sh
source "$SCRIPT_DIR/init/toolchains.sh"
# shellcheck source=setup/init/zsh.sh
source "$SCRIPT_DIR/init/zsh.sh"
# shellcheck source=setup/init/command-help.sh
source "$SCRIPT_DIR/init/command-help.sh"
# shellcheck source=setup/init/manual.sh
source "$SCRIPT_DIR/init/manual.sh"

usage() {
    cat <<'EOF'
Usage: ./setup/init.sh [target] [options]

Targets:
  all             Initialize every managed machine capability (default)
  homebrew        Install Homebrew and the Brewfile inventory
  standalone      Install allowlisted first-party tools
  toolchains      Install toolchains from the tracked mise config
  zsh             Initialize Zsh plugins and generated completions
  command-help    Initialize cheat and tldr data
  manual          Print the manual initialization checklist

Options:
  --dry-run           Print actions without changing files
  --update-plugins    Update existing Zsh plugin checkouts
  -h, --help          Show this help
EOF
}

parse_args() {
    local target_set=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            all|homebrew|standalone|toolchains|zsh|command-help|manual)
                if $target_set; then
                    log_error "Only one init target may be selected"
                    usage
                    exit 1
                fi
                TARGET="$1"
                target_set=true
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            --update-plugins)
                UPDATE_PLUGINS=true
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown init argument '$1'"
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
            ensure_tooling_prerequisites
            install_brew_bundle
            install_standalone_tools
            setup_zsh_environment
            install_mise_toolchains
            setup_command_help
            ;;
        homebrew)
            preflight
            ensure_tooling_prerequisites
            install_brew_bundle
            ;;
        standalone)
            preflight
            install_standalone_tools
            ;;
        toolchains)
            preflight
            install_mise_toolchains
            ;;
        zsh)
            preflight
            setup_zsh_environment
            ;;
        command-help)
            preflight
            setup_command_help
            ;;
        manual)
            print_manual_install_checklist
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
        log_skip "Init target '$TARGET' finished"
    fi
}

main "$@"
