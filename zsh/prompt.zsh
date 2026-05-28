# ----------------------------------------
# File: prompt.zsh
# Description: ZSH prompt configuration
# ----------------------------------------

# ----------------------------------------
# Usage:
# This file configures the ZSH prompt.
# Currently using Starship for the prompt.
# ----------------------------------------

# Initialize Starship once per shell — reload must not re-wrap zle-keymap-select
# (breaks vi mode and shift-select; see starship/starship#3418)
if [[ -z "${STARSHIP_SHELL:-}" ]]; then
    eval "$(starship init zsh)"
fi
