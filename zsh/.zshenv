# ----------------------------------------
# Shared Environment
# ----------------------------------------
_dotfiles_dir="${DOTFILES_DIR:-$HOME/dotfiles}"
source "$_dotfiles_dir/shell/env.sh"
unset _dotfiles_dir

# ----------------------------------------
# SSH agent — 1Password is the current truth. Proton Pass remains optional
# while it is being evaluated. Both checks are socket-gated, so machines
# running only one agent are unaffected; when both sockets exist, 1Password
# wins because its check runs last.
# pass-cli's daemon defaults to ~/.ssh/proton-pass-agent.sock.
# ----------------------------------------
if [[ -S "$PROTON_PASS_SSH_AUTH_SOCK" ]]; then
    export SSH_AUTH_SOCK="$PROTON_PASS_SSH_AUTH_SOCK"
fi

if [[ -S "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" ]]; then
    export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
fi

# ----------------------------------------
# PATH
# ----------------------------------------
source "$ZSH_DIR/path.zsh"
if [[ ! -o login ]]; then
    dotfiles_harden_path
fi
