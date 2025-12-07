# ----------------------------------------
# File: options.zsh
# Description: ZSH shell options
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
