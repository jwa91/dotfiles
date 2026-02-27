#!/usr/bin/env bash
# ----------------------------------------
# File: setup/bootstrap.sh
# Description: Canonical dotfiles bootstrap entrypoint (v2)
# Usage: ./setup/bootstrap.sh [--dry-run] [--no-brew] [--no-link]
# ----------------------------------------

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DRY_RUN=false
SKIP_BREW=false
SKIP_LINK=false

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
        -h|--help)
            echo "Usage: ./setup/bootstrap.sh [--dry-run] [--no-brew] [--no-link]"
            exit 0
            ;;
        *)
            echo -e "${RED}Error:${NC} Unknown option '$1'"
            echo "Usage: ./setup/bootstrap.sh [--dry-run] [--no-brew] [--no-link]"
            exit 1
            ;;
    esac
    shift
done

log_section() { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }
log_skip() { echo -e "${GREEN}✓ SKIP:${NC} $1"; }
log_action() {
    if $DRY_RUN; then
        echo -e "${YELLOW}○ WOULD:${NC} $1"
    else
        echo -e "${YELLOW}→ ACTION:${NC} $1"
    fi
}
log_warn() { echo -e "${YELLOW}⚠ WARN:${NC} $1"; }
log_error() { echo -e "${RED}✗ ERROR:${NC} $1"; }

run_cmd() {
    if $DRY_RUN; then
        echo -e "${YELLOW}○ WOULD:${NC} $*"
    else
        "$@"
    fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ZSH_DIR="$DOTFILES_DIR/zsh"
CONFIG_DIR="$DOTFILES_DIR/config"
BREWFILE="$DOTFILES_DIR/Brewfile"
MANUAL_INSTALLS_FILE="$DOTFILES_DIR/setup/manual-installs.txt"
DOTFILES_LOCAL_CONFIG_DIR="${DOTFILES_LOCAL_CONFIG_DIR:-$HOME/.config/dotfiles-local}"

ensure_dir() {
    local path="$1"
    if [[ -d "$path" ]]; then
        log_skip "$path"
    else
        log_action "Create directory $path"
        run_cmd mkdir -p "$path"
    fi
}

conflict_error() {
    local target="$1"
    local source="$2"
    local backup_path="${target}.backup.$(date +%Y%m%d%H%M%S)"

    log_error "Target exists and is not a symlink: $target"
    echo ""
    echo "Resolve conflict with:"
    echo "  mv \"$target\" \"$backup_path\""
    echo "  ln -s \"$source\" \"$target\""
    echo ""
    echo "Then rerun: ./setup/bootstrap.sh"
    exit 1
}

ensure_symlink() {
    local target="$1"
    local source="$2"
    local parent_dir

    parent_dir="$(dirname "$target")"
    if [[ ! -d "$parent_dir" ]]; then
        log_action "Create directory $parent_dir"
        run_cmd mkdir -p "$parent_dir"
    fi

    if [[ -L "$target" ]]; then
        if [[ "$target" -ef "$source" ]]; then
            log_skip "$target -> $source"
        else
            log_action "Update symlink $target -> $source"
            run_cmd ln -sfn "$source" "$target"
        fi
    elif [[ -e "$target" ]]; then
        if [[ "$target" -ef "$source" ]]; then
            log_skip "$target -> $source (via hardlink)"
        else
            conflict_error "$target" "$source"
        fi
    else
        log_action "Create symlink $target -> $source"
        run_cmd ln -s "$source" "$target"
    fi
}

ensure_local_runtime_file() {
    local runtime_file="$1"
    local example_file="$2"
    local runtime_dir

    runtime_dir="$(dirname "$runtime_file")"
    if [[ ! -d "$runtime_dir" ]]; then
        log_action "Create directory $runtime_dir"
        run_cmd mkdir -p "$runtime_dir"
    fi

    if [[ ! -f "$runtime_file" ]]; then
        if [[ -f "$example_file" ]]; then
            log_action "Initialize $runtime_file from $example_file"
            run_cmd cp "$example_file" "$runtime_file"
            log_warn "Review $runtime_file and fill local values before use"
        else
            log_action "Create empty runtime config $runtime_file"
            run_cmd touch "$runtime_file"
            log_warn "Populate $runtime_file before use"
        fi
    else
        log_skip "$runtime_file"
    fi
}

is_cursor_installed() {
    if command -v cursor >/dev/null 2>&1; then
        return 0
    fi

    if [[ -d "/Applications/Cursor.app" || -d "$HOME/Applications/Cursor.app" ]]; then
        return 0
    fi

    return 1
}

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

preflight() {
    log_section "Preflight"

    if [[ "$(uname -s)" != "Darwin" ]]; then
        log_error "This bootstrap currently supports macOS only."
        exit 1
    fi

    for required in "$BREWFILE" "$ZSH_DIR/.zshrc" "$ZSH_DIR/.zshenv" "$CONFIG_DIR"; do
        if [[ ! -e "$required" ]]; then
            log_error "Required path missing: $required"
            exit 1
        fi
    done

    log_skip "Repository root: $DOTFILES_DIR"
    log_skip "Brewfile: $BREWFILE"
}

ensure_homebrew_and_git() {
    log_section "Tooling Prerequisites"

    if command -v brew >/dev/null 2>&1; then
        log_skip "Homebrew"
    else
        if $SKIP_BREW; then
            log_error "Homebrew is missing and --no-brew was set."
            exit 1
        fi

        log_action "Install Homebrew"
        run_cmd /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        if ! $DRY_RUN; then
            if [[ -x /opt/homebrew/bin/brew ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -x /usr/local/bin/brew ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        fi
    fi

    if command -v git >/dev/null 2>&1; then
        log_skip "Git"
    else
        if $SKIP_BREW; then
            log_error "Git is missing and --no-brew was set."
            exit 1
        fi
        log_action "Install git via Homebrew"
        run_cmd brew install git
    fi
}

install_brew_bundle() {
    log_section "Homebrew Bundle"

    if $SKIP_BREW; then
        log_skip "brew bundle step (--no-brew)"
        return
    fi

    log_action "Run brew bundle --file=$BREWFILE"
    run_cmd brew bundle --file="$BREWFILE"
}

install_standalone_tools() {
    log_section "Standalone Tools (non-Homebrew)"

    if $SKIP_BREW; then
        log_skip "standalone tools step (--no-brew)"
        return
    fi

    # Amp (Sourcegraph) — https://ampcode.com
    if command -v amp >/dev/null 2>&1; then
        log_skip "amp (already installed)"
    else
        local amp_url="https://ampcode.com/install.sh"
        log_action "Install amp via $amp_url"
        if ! $DRY_RUN; then
            if curl -fsSL --head "$amp_url" >/dev/null 2>&1; then
                curl -fsSL "$amp_url" | bash
            else
                log_warn "amp install script unreachable at $amp_url — install manually: https://ampcode.com"
            fi
        fi
    fi
}

setup_zsh_environment() {
    log_section "Zsh Environment"

    ensure_dir "$HOME/.zsh_plugins"
    ensure_dir "$HOME/Developer"
    ensure_dir "$HOME/.local/bin"
    ensure_dir "$HOME/.npm-global/bin"

    local plugins=(
        "zsh-autosuggestions:https://github.com/zsh-users/zsh-autosuggestions"
        "zsh-syntax-highlighting:https://github.com/zsh-users/zsh-syntax-highlighting"
        "zsh-history-substring-search:https://github.com/zsh-users/zsh-history-substring-search"
    )

    local plugin
    for plugin in "${plugins[@]}"; do
        local name="${plugin%%:*}"
        local url="${plugin#*:}"
        local path="$HOME/.zsh_plugins/$name"

        if [[ -d "$path" ]]; then
            log_skip "$path"
        else
            log_action "Clone $name"
            run_cmd git clone --depth 1 "$url" "$path"
        fi
    done

}

link_configs() {
    log_section "Link Dotfiles & App Configs"

    if $SKIP_LINK; then
        log_skip "linking step (--no-link)"
        return
    fi

    # Shell and terminal configs
    ensure_symlink "$HOME/.zshrc" "$ZSH_DIR/.zshrc"
    ensure_symlink "$HOME/.zshenv" "$ZSH_DIR/.zshenv"
    ensure_symlink "$HOME/.zprofile" "$ZSH_DIR/.zprofile"
    ensure_symlink "$HOME/.config/ghostty/config" "$CONFIG_DIR/ghostty/config"
    ensure_symlink "$HOME/.config/starship.toml" "$CONFIG_DIR/starship.toml"
    ensure_symlink "$HOME/.config/fresh/config.json" "$CONFIG_DIR/fresh/config.json"

    # Cursor (manual install in v2)
    if is_cursor_installed; then
        ensure_symlink "$HOME/Library/Application Support/Cursor/User/settings.json" "$CONFIG_DIR/cursor/settings.json"
        ensure_symlink "$HOME/Library/Application Support/Cursor/User/keybindings.json" "$CONFIG_DIR/cursor/keybindings.json"
        ensure_symlink "$HOME/Library/Application Support/Cursor/User/snippets" "$CONFIG_DIR/cursor/snippets"

        local cursor_runtime="$DOTFILES_LOCAL_CONFIG_DIR/cursor/mcp.json"
        ensure_local_runtime_file "$cursor_runtime" "$CONFIG_DIR/cursor/mcp.example.json"
        ensure_symlink "$HOME/.cursor/mcp.json" "$cursor_runtime"
    else
        log_warn "Cursor not detected; skipping Cursor config links for now"
        log_warn "Install Cursor manually, then rerun: ./setup/bootstrap.sh --no-brew"
    fi

    # VS Code
    ensure_symlink "$HOME/Library/Application Support/Code/User/settings.json" "$CONFIG_DIR/vscode/settings.json"
    ensure_symlink "$HOME/Library/Application Support/Code/User/keybindings.json" "$CONFIG_DIR/vscode/keybindings.json"
    ensure_symlink "$HOME/Library/Application Support/Code/User/snippets" "$CONFIG_DIR/vscode/snippets"

    # Claude Code
    ensure_symlink "$HOME/.claude/settings.json" "$CONFIG_DIR/claude-code/settings.json"

    # Codex
    ensure_symlink "$HOME/.codex/config.toml" "$CONFIG_DIR/codex/config.toml"

    # GH
    ensure_symlink "$HOME/.config/gh/config.yml" "$CONFIG_DIR/gh/config.yml"

    # Cheat
    ensure_symlink "$HOME/.config/cheat/conf.yml" "$CONFIG_DIR/cheat/conf.yml"
    ensure_symlink "$HOME/.config/cheat/cheatsheets/personal" "$CONFIG_DIR/cheat/cheatsheets"

    # Yazi
    ensure_symlink "$HOME/.config/yazi/yazi.toml" "$CONFIG_DIR/yazi/yazi.toml"

    # tmux
    ensure_symlink "$HOME/.tmux.conf" "$CONFIG_DIR/tmux/tmux.conf"
}

main() {
    if $DRY_RUN; then
        echo -e "${BLUE}🔍 DRY RUN MODE - No changes will be made${NC}"
    fi

    preflight
    ensure_homebrew_and_git
    install_brew_bundle
    install_standalone_tools
    setup_zsh_environment
    print_manual_install_checklist
    link_configs

    log_section "Complete"
    echo -e "${GREEN}✓ Bootstrap finished${NC}"
}

main "$@"
