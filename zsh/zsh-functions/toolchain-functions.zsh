# ----------------------------------------
# File: toolchain-functions.zsh
# Description: Keep language toolchain mutations routed through mise.
# ----------------------------------------

_toolchain_nudge() {
  local command_name="$1"
  shift
  local line

  echo "x $command_name is not the owner for this mutation." >&2
  echo "  Homebrew owns mise; mise owns Go, Rust, Node, pnpm, and Bun versions." >&2
  for line in "$@"; do
    echo "$line" >&2
  done
  return 127
}

_run_external_tool() {
  local command_name="$1"
  shift

  command "$command_name" "$@"
}

_toolchain_has_global_flag() {
  local arg previous=""

  for arg in "$@"; do
    case "$arg" in
      -g|--global|--location=global)
        return 0
        ;;
    esac

    if [[ "$previous" == "--location" && "$arg" == "global" ]]; then
      return 0
    fi

    previous="$arg"
  done

  return 1
}

bun() {
  case "${1:-}" in
    upgrade)
      _toolchain_nudge "bun upgrade" \
        "  Use: mise upgrade bun" \
        "  Or update the project/global mise.toml intentionally."
      ;;
    add|install)
      if _toolchain_has_global_flag "$@"; then
        _toolchain_nudge "bun $1 -g" \
          "  Use project dependencies, or install JS CLIs through mise's npm: backend or the Brewfile." \
          "  Use mise use bun@<version> only for the Bun runtime itself."
      else
        _run_external_tool bun "$@"
      fi
      ;;
    *)
      _run_external_tool bun "$@"
      ;;
  esac
}

npm() {
  if [[ "${1:-}" == "install" || "${1:-}" == "i" ]] && _toolchain_has_global_flag "$@"; then
    _toolchain_nudge "npm $1 -g" \
      "  Use project dependencies, or install CLIs through mise: mise use npm:<package>@<version>."
  else
    _run_external_tool npm "$@"
  fi
}

pnpm() {
  if [[ "${1:-}" == "add" || "${1:-}" == "install" ]] && _toolchain_has_global_flag "$@"; then
    _toolchain_nudge "pnpm $1 -g" \
      "  Use project dependencies, or install CLIs through mise: mise use npm:<package>@<version>."
  else
    _run_external_tool pnpm "$@"
  fi
}

yarn() {
  if [[ "${1:-}" == "global" ]]; then
    _toolchain_nudge "yarn global" \
      "  Use project dependencies, or install CLIs through mise."
  else
    _run_external_tool yarn "$@"
  fi
}

go() {
  if [[ "${1:-}" == "env" && "${2:-}" == "-w" ]]; then
    _toolchain_nudge "go env -w" \
      "  Put persistent Go environment in mise.toml, shell/env.sh, or project config."
  elif [[ "${1:-}" == "install" ]]; then
    _toolchain_nudge "go install" \
      "  Use go build or go run for project-local binaries." \
      "  Use mise for Go CLIs: mise use go:<module>@<version>, or add the tool to the Brewfile."
  else
    _run_external_tool go "$@"
  fi
}

cargo() {
  if [[ "${1:-}" == "install" ]]; then
    _toolchain_nudge "cargo install" \
      "  Use mise for Rust CLIs: mise use cargo:<crate>@<version>." \
      "  Escape hatch: command cargo install --path ."
  else
    _run_external_tool cargo "$@"
  fi
}

rustup() {
  case "${1:-}" in
    update|default|override)
      _toolchain_nudge "rustup $1" \
        "  Use mise for Rust versions: mise use rust@stable or project mise.toml."
      ;;
    toolchain)
      if [[ "${2:-}" == "install" || "${2:-}" == "uninstall" || "${2:-}" == "link" ]]; then
        _toolchain_nudge "rustup toolchain $2" \
          "  Use mise for Rust toolchains: mise use rust@<version>."
      else
        _run_external_tool rustup "$@"
      fi
      ;;
    target|component)
      if [[ "${2:-}" == "add" || "${2:-}" == "remove" ]]; then
        _toolchain_nudge "rustup $1 $2" \
          "  Put Rust $1 requirements in mise.toml tool options."
      else
        _run_external_tool rustup "$@"
      fi
      ;;
    self)
      if [[ "${2:-}" == "update" || "${2:-}" == "uninstall" ]]; then
        _toolchain_nudge "rustup self $2" \
          "  Let mise/rustup manage the implementation state; update through mise intentionally."
      else
        _run_external_tool rustup "$@"
      fi
      ;;
    *)
      _run_external_tool rustup "$@"
      ;;
  esac
}
