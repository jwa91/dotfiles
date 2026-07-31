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

# History. Lives under XDG state; setup/init/zsh.sh migrates the old
# ~/.zsh_history in place, but create the directory here too so a shell opened
# before setup runs does not silently drop its history.
[[ -d "$ZSH_STATE_DIR" ]] || mkdir -p "$ZSH_STATE_DIR"
HISTFILE="$ZSH_STATE_DIR/history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt SHARE_HISTORY
