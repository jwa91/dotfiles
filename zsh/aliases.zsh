# ----------------------------------------
# File: aliases.zsh
# Description: Custom aliases for zsh
# ----------------------------------------

# ZSH configuration aliases
alias reload='source ~/.zshrc'
alias reloadenv='source ~/.zshenv'
open_in_editor() {
  local target="$1"

  if command -v cursor >/dev/null 2>&1; then
    cursor "$target"
  elif [[ -d "/Applications/Cursor.app" || -d "$HOME/Applications/Cursor.app" ]]; then
    open -a "Cursor" "$target"
  elif command -v code >/dev/null 2>&1; then
    code "$target"
  elif [[ -d "/Applications/Visual Studio Code.app" ]]; then
    open -a "Visual Studio Code" "$target"
  else
    open "$target"
  fi
}

edit_zsh() { open_in_editor "$ZSH_DIR"; }
edit_dotfiles() { open_in_editor "$DOTFILES_DIR"; }

# Notes/Vault aliases (functions required for iCloud path with spaces)
unalias vault edit_notes 2>/dev/null
vault() { open_in_editor "$VAULT_PATH"; }
edit_notes() { open_in_editor "$VAULT_PATH"; }


# Utility shell scripts
# Active scripts - Managed via external tools/path
# See setup/bootstrap.sh for setup instructions

# File system aliases
alias ls='ls -FaG'

# tmux aliases
alias tmain='tmux new-session -A -s main'
alias tls='tmux list-sessions'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Python environment aliases
alias clean_pycache='find . -name "__pycache__" -type d -exec rm -rf {} +'

alias pass="openssl rand -hex 32 | pbcopy && echo '✅ Password copied to clipboard'"
