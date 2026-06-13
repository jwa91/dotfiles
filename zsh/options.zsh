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

# Treat # as a comment marker in interactive shells, matching bash behavior.
setopt INTERACTIVE_COMMENTS

# History
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt SHARE_HISTORY
