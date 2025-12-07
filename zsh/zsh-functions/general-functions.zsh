# ----------------------------------------
# File: general-functions.zsh
# Description: General purpose functions for file and system management
# Author: Jan Willem Altink
# Last Modified: 2024-07-29
# ----------------------------------------

# --------------------------------------------------
# Function: load_key
# Description: Loads API keys from 1Password by name.
#              Keys in 1Password should match the env var name (e.g., OPENAI_API_KEY).
# Usage: load_key OPENAI_API_KEY [ANTHROPIC_API_KEY ...]
# --------------------------------------------------
function load_key() {
  local secret
  for key in "$@"; do
    if ! secret=$(op read "op://Personal/$key/credential"); then
      echo "✗ $key (op read failed)" >&2
      return 1
    fi
    export "$key=$secret"
    echo "✓ $key"
  done
}

# --------------------------------------------------
# Function: rwe (Retry With Escapes)
# Description: Retries the last command with escaped arguments if it failed due to globbing issues.
# Usage: rwe
# --------------------------------------------------
function rwe() {
  local last_cmd=$(fc -ln -1)

  eval "$last_cmd" 2> /tmp/rwe-error.log
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    return 0
  fi

  if grep -q "no matches found" /tmp/rwe-error.log; then
    local parts=()
    IFS=' ' read -r -A parts <<< "$last_cmd"

    local cmd="${parts[1]}"
    local args=("${parts[@]:1}")

    local escaped=()
    for arg in "${args[@]}"; do
      escaped+=("${(q)arg}")
    done

    echo "⚠️  Retrying with escaped arguments:"
    echo "$cmd ${escaped[*]}"
    eval "$cmd ${escaped[*]}"
  else
    cat /tmp/rwe-error.log
    return $exit_code
  fi
}

# --------------------------------------------------
# Function: cdd
# Description: Navigates to the developer directory (DEV_DIR) or a specific subdirectory within it. Uses completion defined in completions.zsh.
# Usage: cdd [subdirectory_name]
# --------------------------------------------------
function cdd() {
    if [[ -z "$DEV_DIR" ]]; then
        echo "cdd: Fout - DEV_DIR env variable not set." >&2
        return 1
    fi
    if [[ ! -d "$DEV_DIR" ]]; then
        echo "cdd: Fout - Developer directory does not exist: $DEV_DIR" >&2
        return 1
    fi

    local target_dir
    if [[ -n "$1" ]]; then
        target_dir="$DEV_DIR/$1"
    else
        target_dir="$DEV_DIR"
    fi

    if builtin cd "$target_dir"; then
        return 0
    else
        return 1
    fi
}

# --------------------------------------------------
# Function: zsh-doctor
# Description: Validates that all dependencies and paths are properly configured.
#              Run this after setup to verify everything is working.
# Usage: zsh-doctor
# --------------------------------------------------
function zsh-doctor() {
    local has_errors=0
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local NC='\033[0m'

    echo -e "🩺 ZSH Doctor - Checking your configuration...\n"

    # --- Check required commands ---
    echo -e "Checking required commands..."
    local commands=("starship" "fzf" "git" "bun" "pnpm" "uv")
    for cmd in "${commands[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            echo -e "  ${GREEN}✓${NC} $cmd"
        else
            echo -e "  ${RED}✗${NC} $cmd (not found)"
            has_errors=1
        fi
    done

    # --- Check optional commands ---
    echo -e "\nChecking optional commands..."
    local optional_commands=("op" "code" "cursor")
    for cmd in "${optional_commands[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            echo -e "  ${GREEN}✓${NC} $cmd"
        else
            echo -e "  ${YELLOW}○${NC} $cmd (not found - optional)"
        fi
    done

    # --- Check environment variables ---
    echo -e "\nChecking environment variables..."
    local env_vars=("DOTFILES_DIR" "ZSH_DIR" "DEV_DIR" "ZSH_PLUGINS_DIR")
    for var in "${env_vars[@]}"; do
        if [[ -n "${(P)var}" ]]; then
            echo -e "  ${GREEN}✓${NC} $var = ${(P)var}"
        else
            echo -e "  ${RED}✗${NC} $var (not set)"
            has_errors=1
        fi
    done

    # --- Check directories ---
    echo -e "\nChecking directories..."
    local dirs=("$DEV_DIR" "$ZSH_PLUGINS_DIR" "$HOME/.local/bin")
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            echo -e "  ${GREEN}✓${NC} $dir"
        else
            echo -e "  ${RED}✗${NC} $dir (does not exist)"
            has_errors=1
        fi
    done

    # --- Check ZSH plugins ---
    echo -e "\nChecking ZSH plugins..."
    local plugins=("zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-history-substring-search")
    for plugin in "${plugins[@]}"; do
        local plugin_path="$ZSH_PLUGINS_DIR/$plugin"
        if [[ -d "$plugin_path" ]]; then
            echo -e "  ${GREEN}✓${NC} $plugin"
        else
            echo -e "  ${RED}✗${NC} $plugin (not installed at $plugin_path)"
            has_errors=1
        fi
    done

    # --- Check symlinks ---
    echo -e "\nChecking symlinks..."
    local symlinks=("$HOME/.zshrc" "$HOME/.zshenv" "$HOME/.zprofile")
    for link in "${symlinks[@]}"; do
        if [[ -L "$link" ]]; then
            local target=$(readlink "$link")
            echo -e "  ${GREEN}✓${NC} $link -> $target"
        elif [[ -f "$link" ]]; then
            echo -e "  ${YELLOW}○${NC} $link (exists but not a symlink)"
        else
            echo -e "  ${RED}✗${NC} $link (does not exist)"
            has_errors=1
        fi
    done

    # --- Check config files ---
    echo -e "\nChecking config files..."
    if [[ -n "$STARSHIP_CONFIG" && -f "$STARSHIP_CONFIG" ]]; then
        echo -e "  ${GREEN}✓${NC} Starship config: $STARSHIP_CONFIG"
    else
        echo -e "  ${YELLOW}○${NC} Starship config not found (using defaults)"
    fi

    # --- Summary ---
    echo ""
    if [[ $has_errors -eq 0 ]]; then
        echo -e "${GREEN}✓ All checks passed!${NC}"
        return 0
    else
        echo -e "${RED}✗ Some checks failed. Run setup.sh to fix issues.${NC}"
        return 1
    fi
}
