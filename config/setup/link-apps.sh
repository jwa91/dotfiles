#!/usr/bin/env bash
# ----------------------------------------
# File: link-apps.sh
# Description: Symlinks application configuration files.
# ----------------------------------------

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo -e "${BLUE}🔍 DRY RUN MODE - No changes will be made${NC}\n"
fi

# Helpers
log_skip() { echo -e "${GREEN}✓ SKIP:${NC} $1"; }
log_action() { 
    if $DRY_RUN; then echo -e "${YELLOW}○ WOULD:${NC} $1"; else echo -e "${YELLOW}→ ACTION:${NC} $1"; fi 
}
log_error() { echo -e "${RED}✗ ERROR:${NC} $1"; }
run_cmd() { if ! $DRY_RUN; then "$@"; fi; }

# Determine dotfiles location
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
CONFIG_DIR="$DOTFILES_DIR/config"

create_symlink() {
    local target="$1"
    local source="$2"
    
    # Check if parent directory exists
    local parent_dir=$(dirname "$target")
    if [[ ! -d "$parent_dir" ]]; then
        if $DRY_RUN; then
             echo -e "${YELLOW}○ WOULD:${NC} Create directory $parent_dir"
        else
             mkdir -p "$parent_dir"
        fi
    fi

    if [[ -L "$target" ]]; then
        current_source=$(readlink "$target")
        if [[ "$current_source" == "$source" ]]; then
            log_skip "$target -> $source"
        else
            log_action "Update symlink $target -> $source"
            run_cmd ln -sf "$source" "$target"
        fi
    elif [[ -e "$target" ]]; then
        if [[ "$target" -ef "$source" ]]; then
            log_skip "$target -> $source (via parent symlink or hardlink)"
        else
            log_error "$target exists but is not a symlink. Please backup/remove manually."
        fi
    else
        log_action "Create symlink $target -> $source"
        run_cmd ln -sf "$source" "$target"
    fi
}

echo -e "\n${BLUE}━━━ Linking Configurations ━━━${NC}"

# --- 1. Cursor ---
# macOS Path: ~/Library/Application Support/Cursor/User/settings.json (and keybindings.json, snippets)
CURSOR_USER_DIR="$HOME/Library/Application Support/Cursor/User"
create_symlink "$CURSOR_USER_DIR/settings.json" "$CONFIG_DIR/cursor/settings.json"
create_symlink "$CURSOR_USER_DIR/keybindings.json" "$CONFIG_DIR/cursor/keybindings.json"
create_symlink "$CURSOR_USER_DIR/snippets" "$CONFIG_DIR/cursor/snippets"

# Cursor Global MCP Config
# Path: ~/.cursor/mcp.json
CURSOR_GLOBAL_DIR="$HOME/.cursor"
if [[ ! -d "$CURSOR_GLOBAL_DIR" ]]; then
    log_action "Create $CURSOR_GLOBAL_DIR"
    run_cmd mkdir -p "$CURSOR_GLOBAL_DIR"
fi
create_symlink "$CURSOR_GLOBAL_DIR/mcp.json" "$CONFIG_DIR/cursor/mcp.json"


# --- 2. VS Code ---
# macOS Path: ~/Library/Application Support/Code/User/settings.json
VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
create_symlink "$VSCODE_USER_DIR/settings.json" "$CONFIG_DIR/vscode/settings.json"
create_symlink "$VSCODE_USER_DIR/keybindings.json" "$CONFIG_DIR/vscode/keybindings.json"
create_symlink "$VSCODE_USER_DIR/snippets" "$CONFIG_DIR/vscode/snippets"

# --- 3. Claude Desktop ---
# Path: ~/Library/Application Support/Claude/claude_desktop_config.json
CLAUDE_DIR="$HOME/Library/Application Support/Claude"
create_symlink "$CLAUDE_DIR/claude_desktop_config.json" "$CONFIG_DIR/claude/claude_desktop_config.json"
# Optional: Developer settings if present
if [[ -f "$CONFIG_DIR/claude/developer_settings.json" ]]; then
    create_symlink "$CLAUDE_DIR/developer_settings.json" "$CONFIG_DIR/claude/developer_settings.json"
fi

# --- 3b. Claude Code ---
# Path: ~/.claude/settings.json, ~/.claude/commands/, and ~/.claude/agents/
CLAUDE_CODE_DIR="$HOME/.claude"
create_symlink "$CLAUDE_CODE_DIR/settings.json" "$CONFIG_DIR/claude-code/settings.json"
create_symlink "$CLAUDE_CODE_DIR/commands" "$CONFIG_DIR/claude-code/commands"
create_symlink "$CLAUDE_CODE_DIR/agents" "$CONFIG_DIR/claude-code/agents"

# --- 4. Codex CLI ---
# Path: ~/.codex/config.toml and ~/.codex/instructions.md
# Note: Only symlink config files, NOT the entire directory
# (auth.json, sessions/, log/ should remain in ~/.codex, not in dotfiles)
CODEX_DIR="$HOME/.codex"
create_symlink "$CODEX_DIR/config.toml" "$CONFIG_DIR/codex/config.toml"
create_symlink "$CODEX_DIR/instructions.md" "$CONFIG_DIR/codex/instructions.md"

# --- 5. GitHub CLI (gh) ---
# Path: ~/.config/gh/config.yml
GH_DIR="$HOME/.config/gh"
create_symlink "$GH_DIR/config.yml" "$CONFIG_DIR/gh/config.yml"

# --- 6. Cheat ---
# Path: ~/.config/cheat/conf.yml and ~/.config/cheat/cheatsheets/personal
CHEAT_DIR="$HOME/.config/cheat"
create_symlink "$CHEAT_DIR/conf.yml" "$CONFIG_DIR/cheat/conf.yml"
# Ensure cheatsheets dir exists
mkdir -p "$CHEAT_DIR/cheatsheets"
create_symlink "$CHEAT_DIR/cheatsheets/personal" "$CONFIG_DIR/cheat/cheatsheets"



echo -e "\n${GREEN}✓ Configuration linking complete!${NC}"

