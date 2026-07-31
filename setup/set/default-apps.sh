#!/usr/bin/env bash
# Converge managed macOS default applications.

apply_default_apps() {
    local defaults_file="$CONFIG_DIR/duti/defaults.duti"
    local launch_services_register="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
    local zed_app cursor_app

    log_section "Default Applications"

    if ! is_zed_installed; then
        log_warn "Zed is not installed; skipping default application setup"
        return
    fi

    if ! command -v duti >/dev/null 2>&1; then
        log_error "duti is not installed; run: ./setup/init.sh homebrew"
        return 1
    fi

    if [[ ! -f "$defaults_file" ]]; then
        log_error "Default application config missing: $defaults_file"
        exit 1
    fi

    if [[ -d "/Applications/Zed.app" ]]; then
        zed_app="/Applications/Zed.app"
    else
        zed_app="$HOME/Applications/Zed.app"
    fi

    if [[ -x "$launch_services_register" ]]; then
        for cursor_app in "/Applications/Cursor.app" "$HOME/Applications/Cursor.app"; do
            if [[ -d "$cursor_app" ]]; then
                log_action "Remove Cursor's competing Launch Services registration"
                run_cmd "$launch_services_register" -u "$cursor_app"
                break
            fi
        done

        log_action "Register Zed as the preferred code editor"
        run_cmd "$launch_services_register" -f "$zed_app"
    fi

    log_action "Apply Zed file associations from $defaults_file"
    run_cmd duti "$defaults_file"
}
