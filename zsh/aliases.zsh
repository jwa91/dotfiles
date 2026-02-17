# ----------------------------------------
# File: aliases.zsh
# Description: Custom aliases for zsh
# ----------------------------------------

# ZSH configuration aliases
alias reload='source ~/.zshrc'
alias reloadenv='source ~/.zshenv'
alias edit_zsh='cursor $ZSH_DIR'
alias edit_dotfiles='cursor $DOTFILES_DIR'

# Notes/Vault aliases (functions required for iCloud path with spaces)
unalias vault edit_notes 2>/dev/null
vault() { open -a "Cursor" "$VAULT_PATH" }
edit_notes() { open -a "Cursor" "$VAULT_PATH" }


# Utility shell scripts
# Active scripts - Managed via external tools/path
# See install-tools.sh for setup instructions

# File system aliases
alias ls='ls -FaG'

# tmux aliases
alias tmain='tmux new-session -A -s main'
alias tls='tmux list-sessions'

# Python environment aliases
alias clean_pycache='find . -name "__pycache__" -type d -exec rm -rf {} +'

alias pass="openssl rand -hex 32 | pbcopy && echo '✅ Password copied to clipboard'"
