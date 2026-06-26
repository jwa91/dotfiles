# ----------------------------------------
# File: toolchain-functions.zsh
# Description: Keep language toolchain mutations routed through their owner.
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

_python_nudge() {
  local command_name="$1"
  shift

  case "$command_name" in
    pip|pip3)
      echo "x uv owns Python dependencies on this machine; skip bare pip." >&2
      echo "  Use: uv add <pkg>          # project dependency" >&2
      echo "  Use: uv pip install <pkg>  # one-off, into the current venv" >&2
      echo "  Escape hatch: command $command_name $*" >&2
      ;;
    python|python3)
      echo "x uv owns Python execution on this machine; skip bare python." >&2
      echo "  Use: uv run <script.py>    # run a script" >&2
      echo "  Use: uv run python         # REPL, or add -m <module>" >&2
      echo "  Escape hatch: command $command_name $*" >&2
      ;;
  esac

  return 127
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

pip() {
  _python_nudge pip "$@"
}

pip3() {
  _python_nudge pip3 "$@"
}

python() {
  _python_nudge python "$@"
}

python3() {
  _python_nudge python3 "$@"
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
