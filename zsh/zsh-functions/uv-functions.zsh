# ----------------------------------------
# File: uv-functions.zsh
# Description: Keep this machine uv-only by nudging bare pip/python toward uv.
# Author: Jan Willem Altink
# ----------------------------------------

# --------------------------------------------------
# Function: _uv_nudge
# Description: Shared helper. Prints the uv equivalent for a bare pip/python
#              call and refuses to run the system interpreter. The last line is
#              the escape hatch: `command pip3` / `command python3` bypass the
#              nudge when you genuinely need the system tool.
# --------------------------------------------------
function _uv_nudge() {
  local kind="$1"; shift
  case "$kind" in
    pip)
      echo "✗ uv-only machine — skip bare pip:" >&2
      echo "    uv add <pkg>          # project dependency" >&2
      echo "    uv pip install <pkg>  # one-off, into the current venv" >&2
      echo "    command pip3 $*       # really run system pip3" >&2
      ;;
    python)
      echo "✗ uv-only machine — skip bare python:" >&2
      echo "    uv run <script.py>    # run a script" >&2
      echo "    uv run python         # REPL, or add -m <module>" >&2
      echo "    command python3 $*    # really run system python3" >&2
      ;;
  esac
  return 127
}

# Shadow the bare commands in interactive shells. Scripts and subprocesses look
# up PATH directly and are unaffected — this only catches what you type.
function pip()     { _uv_nudge pip "$@"; }
function pip3()    { _uv_nudge pip "$@"; }
function python()  { _uv_nudge python "$@"; }
function python3() { _uv_nudge python "$@"; }
