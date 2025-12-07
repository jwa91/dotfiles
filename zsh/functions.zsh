# ----------------------------------------
# File: functions.zsh
# Description: Sources function files for zsh
# ----------------------------------------

FUNCTIONS_DIR="$ZSH_DIR/zsh-functions"

# Load general functions
source "$FUNCTIONS_DIR/general-functions.zsh"

# Next.js functions
source "$FUNCTIONS_DIR/nextjs-functions.zsh"

# Python functions (external from templates repo)
if [[ -f "$HOME/Developer/templates/python/python-functions.sh" ]]; then
    source "$HOME/Developer/templates/python/python-functions.sh"
fi
