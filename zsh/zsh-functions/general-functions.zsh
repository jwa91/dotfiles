# ----------------------------------------
# File: general-functions.zsh
# Description: General purpose functions for file and system management
# Author: Jan Willem Altink
# ----------------------------------------

# --------------------------------------------------
# Function: key
# Description: Loads API keys from Proton Pass by name.
#              Items should match the env var name (e.g., OPENAI_API_KEY).
#              The field defaults to "credential"; override with PROTON_PASS_KEY_FIELD.
# Usage: key OPENAI_API_KEY [ANTHROPIC_API_KEY ...]
# --------------------------------------------------
function key() {
  local key secret vault field ref
  vault="${PROTON_PASS_VAULT:-Personal}"
  field="${PROTON_PASS_KEY_FIELD:-credential}"

  for key in "$@"; do
    ref="pass://$vault/$key/$field"
    if ! secret=$(pass-cli item view "$ref" 2>/dev/null); then
      if [[ "$field" != "password" ]]; then
        ref="pass://$vault/$key/password"
        secret=$(pass-cli item view "$ref" 2>/dev/null) || {
          echo "✗ $key (pass-cli item view failed for credential/password)" >&2
          return 1
        }
      else
        echo "✗ $key (pass-cli item view failed)" >&2
        return 1
      fi
    fi

    if [[ -z "$secret" ]]; then
      echo "✗ $key (empty Proton Pass field)" >&2
      return 1
    fi

    export "$key=$secret"
    echo "✓ $key"
  done
}

# --------------------------------------------------
# Function: ppagent
# Description: Manage the Proton Pass SSH agent for this machine's work vault.
# Usage: ppagent [start|restart|stop|status]
# --------------------------------------------------
function ppagent() {
  local action="${1:-status}"
  local vault="${PROTON_PASS_SSH_VAULT:-Work}"
  local socket_path="${PROTON_PASS_SSH_AUTH_SOCK:-$HOME/.ssh/proton-pass-agent.sock}"

  case "$action" in
    start)
      pass-cli ssh-agent daemon start \
        --vault-name "$vault" \
        --create-new-identities "$vault" \
        --socket-path "$socket_path"
      ;;
    restart)
      pass-cli ssh-agent daemon stop 2>/dev/null
      pass-cli ssh-agent daemon start \
        --vault-name "$vault" \
        --create-new-identities "$vault" \
        --socket-path "$socket_path"
      ;;
    stop)
      pass-cli ssh-agent daemon stop
      ;;
    status)
      pass-cli ssh-agent daemon status
      ;;
    *)
      echo "Usage: ppagent [start|restart|stop|status]" >&2
      return 2
      ;;
  esac
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
