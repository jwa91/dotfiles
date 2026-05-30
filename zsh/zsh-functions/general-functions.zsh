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
