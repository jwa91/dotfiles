# ----------------------------------------
# File: shift-select.zsh
# Description: Shift+Arrow selection mode for ZLE (macOS-focused)
# ----------------------------------------

[[ "${SHIFT_SELECT:-true}" == "true" ]] || return 0

# Keep custom end-of-buffer behavior aligned with syntax highlighting redraw.
function _shiftselect_end_of_buffer() {
    CURSOR=${#BUFFER}
    zle end-of-line -w
}

# Keep custom beginning-of-buffer behavior aligned with syntax highlighting redraw.
function _shiftselect_beginning_of_buffer() {
    CURSOR=0
    zle beginning-of-line -w
}

function _shiftselect_kill_region() {
    zle kill-region -w
    zle -K main
}
zle -N _shiftselect_kill_region

function _shiftselect_deselect_and_input() {
    zle deactivate-region -w
    zle -K main
    zle -U "$KEYS"
}
zle -N _shiftselect_deselect_and_input

function _shiftselect_select_and_invoke() {
    if (( !REGION_ACTIVE )); then
        zle set-mark-command -w
        zle -K shift-select
    fi

    local target=${WIDGET#_shiftselect_}
    case "$target" in
        beginning-of-buffer) zle _shiftselect_beginning_of_buffer -w ;;
        end-of-buffer) zle _shiftselect_end_of_buffer -w ;;
        *) zle "$target" -w ;;
    esac
}

function _shiftselect_setup() {
    emulate -L zsh

    # Recreate keymap on reload; avoid inheriting emacs bindings here.
    bindkey -D shift-select 2>/dev/null
    bindkey -N shift-select
    bindkey -M shift-select -R '^@'-'^?' _shiftselect_deselect_and_input

    local seq widget

    zle -N _shiftselect_beginning_of_buffer _shiftselect_beginning_of_buffer
    zle -N _shiftselect_end_of_buffer _shiftselect_end_of_buffer

    # Mac-focused key sequences (modifier 4=Shift+Option, 6/10=Shift+Cmd, 2=Shift+Home).
    for seq widget in \
        '^[[1;2D' backward-char \
        '^[[1;2C' forward-char \
        '^[[1;2A' up-line \
        '^[[1;2B' down-line \
        '^[[1;2H' beginning-of-line \
        '^[[1;2F' end-of-line \
        '^[[97;6u' beginning-of-line \
        '^[[101;6u' end-of-line \
        '^[[1;4D' backward-word \
        '^[[1;4C' forward-word \
        '^[[1;6D' beginning-of-line \
        '^[[1;6C' end-of-line \
        '^[[1;10D' beginning-of-line \
        '^[[1;10C' end-of-line \
        '^[[1;4H' beginning-of-buffer \
        '^[[1;6H' beginning-of-buffer \
        '^[[1;10H' beginning-of-buffer \
        '^[[1;4F' end-of-buffer \
        '^[[1;6F' end-of-buffer \
        '^[[1;10F' end-of-buffer \
    ; do
        zle -N _shiftselect_${widget} _shiftselect_select_and_invoke
        bindkey -M emacs "$seq" _shiftselect_${widget}
        bindkey -M viins "$seq" _shiftselect_${widget}
        bindkey -M shift-select "$seq" _shiftselect_${widget}
    done

    bindkey -M shift-select '^[[3~' _shiftselect_kill_region
    bindkey -M shift-select '^?' _shiftselect_kill_region
}

_shiftselect_setup
