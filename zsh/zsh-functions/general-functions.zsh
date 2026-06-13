# ----------------------------------------
# File: general-functions.zsh
# Description: Parent-shell helpers that must run as functions.
# Author: Jan Willem Altink
# ----------------------------------------

# --------------------------------------------------
# Function: key
# Description: Loads API keys from 1Password by name. 1Password is the
#              current secrets truth. `pkey` is the Proton Pass experiment,
#              kept separate so the default workflow remains unambiguous.
#              Keys in 1Password should match the env var name (e.g., OPENAI_API_KEY).
# Usage: key OPENAI_API_KEY [ANTHROPIC_API_KEY ...]
# --------------------------------------------------
function key() {
  local key secret
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
# Function: pkey
# Description: Loads API keys from Proton Pass by name.
#              Items should match the env var name (e.g., OPENAI_API_KEY).
#              The field defaults to "credential"; override with PROTON_PASS_KEY_FIELD.
# Usage: pkey OPENAI_API_KEY [ANTHROPIC_API_KEY ...]
# --------------------------------------------------
function pkey() {
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
