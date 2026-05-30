#!/usr/bin/env bash

print_manual_install_checklist() {
    log_section "Manual Install Checklist"

    if [[ ! -f "$MANUAL_INSTALLS_FILE" ]]; then
        log_skip "No manual install checklist found at $MANUAL_INSTALLS_FILE"
        return
    fi

    log_warn "The following tools are managed outside Homebrew:"
    while IFS= read -r line; do
        if [[ "$line" =~ ^-[[:space:]]+(.+) ]]; then
            echo "  - ${BASH_REMATCH[1]}"
        fi
    done < "$MANUAL_INSTALLS_FILE"

    echo "  -> Details: $MANUAL_INSTALLS_FILE"
}
