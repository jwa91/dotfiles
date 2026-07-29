# shellcheck shell=bash

dotfiles_has_global_flag() {
  local arg previous=""

  for arg in "$@"; do
    case "$arg" in
      -g|--global|--location=global)
        return 0
        ;;
    esac

    [[ "$previous" == "--location" && "$arg" == "global" ]] && return 0
    previous="$arg"
  done

  return 1
}
