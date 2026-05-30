# ----------------------------------------
# File: general-functions.zsh
# Description: General purpose functions for file and system management
# Author: Jan Willem Altink
# ----------------------------------------

# --------------------------------------------------
# Function: key
# Description: Loads API keys from 1Password by name.
#              Keys in 1Password should match the env var name (e.g., OPENAI_API_KEY).
# Usage: key OPENAI_API_KEY [ANTHROPIC_API_KEY ...]
# --------------------------------------------------
function key() {
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
        echo "cdd: Error - DEV_DIR env variable not set." >&2
        return 1
    fi
    if [[ ! -d "$DEV_DIR" ]]; then
        echo "cdd: Error - Developer directory does not exist: $DEV_DIR" >&2
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
# Function: getmd
# Description: Fetches clean markdown from a URL via defuddle.md API.
#              Copies to clipboard by default. Use --no-copy to print to stdout instead.
# Usage: getmd <url> [--no-copy]
# --------------------------------------------------
function getmd() {
  if [[ -z "$1" ]]; then
    echo "Usage: getmd <url> [--no-copy]" >&2
    return 1
  fi

  local url="${1#https://}"
  url="${url#http://}"
  local no_copy=false
  [[ "$2" == "--no-copy" ]] && no_copy=true

  local content
  content=$(curl -sf "defuddle.md/$url")
  if [[ $? -ne 0 || -z "$content" ]]; then
    echo "✗ Failed to fetch markdown for $url" >&2
    return 1
  fi

  echo "$content"
  if ! $no_copy; then
    echo "$content" | pbcopy
    local wc=$(echo "$content" | wc -w | tr -d ' ')
    echo "✓ Copied ${wc} words to clipboard" >&2
  fi
}

# --------------------------------------------------
# Function: zshdoctor
# Description: Validates that all dependencies and paths are properly configured.
#              Run this after setup to verify everything is working.
# Usage: zshdoctor
# --------------------------------------------------
function zshdoctor() {
    local has_errors=0
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local NC='\033[0m'

    echo -e "🩺 ZSH Doctor - Checking your configuration...\n"

    echo -e "Checking shell commands..."
    local commands=(
        brew git starship fzf tmux micro zoxide atuin
        op jq rg
    )
    for cmd in "${commands[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            echo -e "  ${GREEN}✓${NC} $cmd"
        else
            echo -e "  ${RED}✗${NC} $cmd (not found)"
            has_errors=1
        fi
    done

    echo -e "\nChecking optional commands..."
    local optional_commands=(amp cursor docker tailscale)
    for cmd in "${optional_commands[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            echo -e "  ${GREEN}✓${NC} $cmd"
        else
            echo -e "  ${YELLOW}○${NC} $cmd (not found - optional)"
        fi
    done

    echo -e "\nChecking environment variables..."
    local env_vars=(
        DOTFILES_DIR CONFIG_DIR GITCONFIG_DIR ZSH_DIR ZSH_PLUGINS_DIR
        DEV_DIR VAULT_PATH STARSHIP_CONFIG EDITOR
    )
    for var in "${env_vars[@]}"; do
        if [[ -n "${(P)var}" ]]; then
            echo -e "  ${GREEN}✓${NC} $var = ${(P)var}"
        else
            echo -e "  ${RED}✗${NC} $var (not set)"
            has_errors=1
        fi
    done

    echo -e "\nChecking directories..."
    local dirs=(
        "$DOTFILES_DIR" "$CONFIG_DIR" "$GITCONFIG_DIR" "$ZSH_DIR"
        "$DEV_DIR" "$ZSH_PLUGINS_DIR" "$HOME/.local/bin"
    )
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            echo -e "  ${GREEN}✓${NC} $dir"
        else
            echo -e "  ${RED}✗${NC} $dir (does not exist)"
            has_errors=1
        fi
    done

    echo -e "\nChecking ZSH plugins..."
    local plugins=(zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search)
    for plugin in "${plugins[@]}"; do
        local plugin_path="$ZSH_PLUGINS_DIR/$plugin"
        if [[ -d "$plugin_path" ]]; then
            echo -e "  ${GREEN}✓${NC} $plugin"
        else
            echo -e "  ${RED}✗${NC} $plugin (not installed at $plugin_path)"
            has_errors=1
        fi
    done

    echo -e "\nChecking managed links..."
    local links=(
        "$HOME/.zshrc:$ZSH_DIR/.zshrc"
        "$HOME/.zshenv:$ZSH_DIR/.zshenv"
        "$HOME/.gitconfig:$GITCONFIG_DIR/config"
        "$HOME/.config/ghostty/config:$CONFIG_DIR/ghostty/config"
        "$HOME/.config/starship.toml:$CONFIG_DIR/starship.toml"
        "$HOME/.tmux.conf:$CONFIG_DIR/tmux/tmux.conf"
    )
    local spec link expected target
    for spec in "${links[@]}"; do
        link="${spec%%:*}"
        expected="${spec#*:}"
        if [[ -L "$link" ]]; then
            target=$(readlink "$link")
            if [[ "$link" -ef "$expected" ]]; then
                echo -e "  ${GREEN}✓${NC} $link -> $target"
            else
                echo -e "  ${RED}✗${NC} $link -> $target (expected $expected)"
                has_errors=1
            fi
        elif [[ -e "$link" ]]; then
            if [[ "$link" -ef "$expected" ]]; then
                echo -e "  ${GREEN}✓${NC} $link -> $expected (via hardlink)"
            else
                echo -e "  ${YELLOW}○${NC} $link (exists but not a symlink)"
            fi
        else
            echo -e "  ${RED}✗${NC} $link (does not exist)"
            has_errors=1
        fi
    done

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
        echo -e "${RED}✗ Some checks failed. Run ./setup/bootstrap.sh to fix setup issues.${NC}"
        return 1
    fi
}
