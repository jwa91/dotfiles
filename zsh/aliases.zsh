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
  "${EDITOR:-micro}" "$target"
}
ezsh()    { _eopen "$ZSH_DIR"; }
edots()   { _eopen "$DOTFILES_DIR"; }
evault()  { _eopen "$VAULT_PATH"; }
edev()    { _eopen "$DEV_DIR"; }
cdzsh()   { builtin cd "$ZSH_DIR"; }
cddots()  { builtin cd "$DOTFILES_DIR"; }
cdvault() { builtin cd "$VAULT_PATH"; }

# Listing (eza icons use EZA_ICONS_AUTO + the Nerd Font configured in Ghostty)
alias ls='eza --group-directories-first'                              # tidy default (dotfiles hidden — use la)
alias la='eza --group-directories-first --all'                        # include dotfiles
alias ll='eza --group-directories-first --long --all --git --header'  # detailed: perms, size, git, header
alias lt='eza --group-directories-first --tree --level=2'             # 2-level tree

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Tmux (t + action)
alias tmain='tmux new-session -A -s main'
alias tls='tmux list-sessions'

# Make (mk + thing)
alias mkpass="openssl rand -hex 32 | pbcopy && echo '✅ Password copied to clipboard'"

# Suffix: edit (type filename to open in $EDITOR)
alias -s md='_eopen'
alias -s json='_eopen'
alias -s yaml='_eopen'
alias -s yml='_eopen'
alias -s toml='_eopen'
alias -s txt='_eopen'
alias -s zsh='_eopen'
alias -s py='_eopen'
alias -s js='_eopen'
alias -s ts='_eopen'
alias -s tsx='_eopen'
alias -s jsx='_eopen'
alias -s css='_eopen'
alias -s swift='_eopen'
alias -s rs='_eopen'
alias -s go='_eopen'
alias -s env='_eopen'

# Suffix: view (type filename to open in default app)
alias -s html='open'
alias -s pdf='open'
alias -s png='open'
alias -s jpg='open'
alias -s jpeg='open'
alias -s svg='open'
alias -s gif='open'
alias -s mp4='open'
alias -s csv='open'
alias -s webp='open'
alias -s mov='open'

# Brew. brewsync converges presence only: installs what's missing, never
# upgrades. `brew upgrade` covers the CLI layer; self-updating casks stay
# app-owned via HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1. Cleanup is dry-run:
# it lists strays but never removes — an automatic cleanup could delete GUI apps.
alias brewsync='HOMEBREW_BUNDLE_NO_UPGRADE=1 brew bundle --file="$DOTFILES_DIR/Brewfile" && { brew bundle cleanup --file="$DOTFILES_DIR/Brewfile" || true; }'
alias brewoutdated='HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1 brew outdated'
alias brewup='HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1 brew upgrade'

# Python
alias pyclean='find . -name "__pycache__" -type d -exec rm -rf {} +'
