# ----------------------------------------
# File: aliases.zsh
# Description: Custom aliases for zsh
# Naming: action prefix + shortest target, mashed (ezsh, mkpass, tls)
# ----------------------------------------

# Shell
alias reload='source ~/.zshrc'
alias reloadenv='source ~/.zshenv'

# Edit (e + target) / Navigate (cd + target)
_eopen() {
  local target="$1"
  case "$TERM_PROGRAM" in
    vscode)   cursor "$target" ;;
    ghostty)  fresh "$target" ;;
    *)        micro "$target" ;;
  esac
}
ezsh()    { _eopen "$ZSH_DIR"; }
edots()   { _eopen "$DOTFILES_DIR"; }
evault()  { _eopen "$VAULT_PATH"; }
edev()    { _eopen "$DEV_DIR"; }
cdzsh()   { builtin cd "$ZSH_DIR"; }
cddots()  { builtin cd "$DOTFILES_DIR"; }
cdvault() { builtin cd "$VAULT_PATH"; }

# Navigation
alias ls='ls -FaG'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Tmux (t + action)
alias tmain='tmux new-session -A -s main'
alias tls='tmux list-sessions'

# Make (mk + thing)
alias mkpass="openssl rand -hex 32 | pbcopy && echo '✅ Password copied to clipboard'"

# Python
alias pyclean='find . -name "__pycache__" -type d -exec rm -rf {} +'
