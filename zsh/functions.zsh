# ----------------------------------------
# File: functions.zsh
# Description: fpath and autoload declarations for parent-shell helpers.
#
# These have to be functions rather than scripts in bin/: they cd or export
# into the calling shell. One file per function under zsh-functions/, loaded on
# first use.
#
# Sourced before completions.zsh so compinit sees the final fpath.
# ----------------------------------------

fpath=("$ZSH_DIR/zsh-functions" $fpath)

autoload -Uz cdd key pkey
