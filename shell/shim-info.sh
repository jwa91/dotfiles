# shellcheck shell=bash

dotfiles_infomsg() {
  local key="$1"
  shift
  local specific_var="DISABLE_DOTFILES_INFOMSG_$key"

  if [[ "${DISABLE_DOTFILES_INFOMSG:-0}" == "1" || "${!specific_var:-0}" == "1" ]]; then
    return 0
  fi

  printf 'dotfiles: %s\n' "$*" >&2
}
