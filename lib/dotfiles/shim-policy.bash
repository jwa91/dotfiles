#!/usr/bin/env bash

dotfiles_has_arg() {
  local expected="$1"
  shift
  local arg

  for arg in "$@"; do
    [[ "$arg" == "$expected" ]] && return 0
  done

  return 1
}

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

dotfiles_nudge() {
  local command_name="$1"
  shift
  local line

  printf 'x %s is not the owner for this mutation.\n' "$command_name" >&2
  printf '%s\n' \
    "  Homebrew owns CLIs; mise owns runtimes; project manifests own dependencies." >&2
  for line in "$@"; do
    printf '%s\n' "$line" >&2
  done
  return 127
}

dotfiles_python_nudge() {
  local command_name="$1"

  case "$command_name" in
    pip|pip3)
      printf 'x bare %s is not the Python package command surface on this machine.\n' "$command_name" >&2
      printf '%s\n' \
        "  Use: uv add <pkg>                      # add a project dependency" \
        "  Use: uv sync                           # create/update the project environment" \
        "  Use: uv run --with <pkg> script.py     # one-off script dependency" \
        "  Use uv pip ... only for explicit legacy/manual virtualenv work." >&2
      ;;
    python|python3)
      printf 'x bare %s is not the Python command surface on this machine.\n' "$command_name" >&2
      printf '%s\n' \
        "  Use: uv run script.py                  # run a Python script" \
        "  Use: uv run --with <pkg> script.py     # run a one-off script with deps" \
        "  Use: uv run python                     # REPL, or add -c/-m as needed" \
        "  Use an explicit interpreter path only when intentionally bypassing uv." >&2
      ;;
  esac

  return 127
}

dotfiles_mise_tool_path() {
  local tool="$1"
  local owner_label="$2"
  local tool_path

  if ! command -v mise >/dev/null 2>&1 \
    || ! tool_path="$(mise which "$tool" 2>/dev/null)" \
    || [[ -z "$tool_path" ]]; then
    printf '%s requires the mise-owned %s baseline; run: just toolchains\n' \
      "$tool" "$owner_label" >&2
    return 127
  fi

  printf '%s\n' "$tool_path"
}

dotfiles_exec_mise_tool() {
  local tool="$1"
  local owner_label="$2"
  shift 2
  local tool_path

  tool_path="$(dotfiles_mise_tool_path "$tool" "$owner_label")" || return
  exec "$tool_path" "$@"
}

dotfiles_exec_node_tool() {
  local tool="$1"
  shift
  local node_path tool_path

  node_path="$(dotfiles_mise_tool_path node Node)" || return
  tool_path="$(dotfiles_mise_tool_path "$tool" Node)" || return
  exec env PATH="$(dirname "$node_path"):$PATH" "$tool_path" "$@"
}

dotfiles_exec_corepack_tool() {
  local package_manager="$1"
  shift
  local node_path corepack_path

  node_path="$(dotfiles_mise_tool_path node Node)" || return
  corepack_path="$(dotfiles_mise_tool_path corepack Node)" || return
  exec env PATH="$(dirname "$node_path"):$PATH" \
    "$corepack_path" "$package_manager" "$@"
}
