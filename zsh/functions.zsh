# ----------------------------------------
# File: functions.zsh
# Description: Sources function files for zsh
# ----------------------------------------

FUNCTIONS_DIR="$ZSH_DIR/zsh-functions"

# Load general functions
source "$FUNCTIONS_DIR/general-functions.zsh"

# Next.js functions
source "$FUNCTIONS_DIR/nextjs-functions.zsh"

# Agent skills functions
source "$FUNCTIONS_DIR/agentskills-functions.zsh"

# Tmux session bookmarks and picker (tpick)
source "$CONFIG_DIR/tmux/tmux-bookmarks.zsh"

# Python functions (external from templates repo)
if [[ -f "$HOME/Developer/templates/python/python-functions.sh" ]]; then
    source "$HOME/Developer/templates/python/python-functions.sh"
fi
