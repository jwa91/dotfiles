# ----------------------------------------
# File: options.zsh
# Description: ZSH shell options
# Author: Jan Willem Altink
# Last Modified: 2024-09-28
# ----------------------------------------

# ----------------------------------------
# Usage:
# This file contains ZSH shell options that control the behavior of the shell.
# These options are loaded by .zshrc.
# ----------------------------------------

# Enable completion
setopt GLOB_COMPLETE
setopt MENU_COMPLETE

# Disable behaviors we don't want
unsetopt AUTO_REMOVE_SLASH
unsetopt LIST_BEEP
