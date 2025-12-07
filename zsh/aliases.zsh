# ----------------------------------------
# File: aliases.zsh
# Description: Custom aliases for zsh
# ----------------------------------------

# ZSH configuration aliases
alias reload='source ~/.zshrc'
alias reloadenv='source ~/.zshenv'
alias edit_zsh='cursor $ZSH_DIR'
alias edit_dotfiles='cursor $DOTFILES_DIR'

# Vault alias - requires VAULT_PATH to be set in secrets.zsh
if [[ -n "$VAULT_PATH" ]]; then
    alias vault='cursor "$VAULT_PATH"'
fi


# Utility shell scripts
# Active scripts - Managed via external tools/path
# See install-tools.sh for setup instructions

# File system aliases
alias ls='ls -FaG'

# Python environment aliases
alias clean_pycache='find . -name "__pycache__" -type d -exec rm -rf {} +'

alias pass="openssl rand -hex 32 | pbcopy && echo '✅ Password copied to clipboard'"

