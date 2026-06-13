# ----------------------------------------
# File: functions.zsh
# Description: Sources function files for zsh
# ----------------------------------------

FUNCTIONS_DIR="$ZSH_DIR/zsh-functions"

# Load general functions
source "$FUNCTIONS_DIR/general-functions.zsh"

# Agent skills functions
source "$FUNCTIONS_DIR/agentskills-functions.zsh"

# uv-only nudges (bare pip/python)
source "$FUNCTIONS_DIR/uv-functions.zsh"

# mise-owned toolchain nudges
source "$FUNCTIONS_DIR/toolchain-functions.zsh"
