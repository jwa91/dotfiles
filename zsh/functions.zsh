# ----------------------------------------
# File: functions.zsh
# Description: Sources function files for zsh
# ----------------------------------------

FUNCTIONS_DIR="$ZSH_DIR/zsh-functions"

# Parent-shell functions: cd/export and interactive command wrappers.
source "$FUNCTIONS_DIR/general-functions.zsh"
source "$FUNCTIONS_DIR/toolchain-functions.zsh"
