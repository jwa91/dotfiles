# ----------------------------------------
# File: agentskills-functions.zsh
# Description: Helper functions for installing agent skills into projects
# Author: Jan Willem Altink
# ----------------------------------------

# --------------------------------------------------
# Function: mkskill
# Description: Installs agent skills into the current project directory.
#              Without arguments, lists all available skills.
#              With a skill name, installs that skill into the current directory.
# Usage: mkskill [skill-name]
# --------------------------------------------------
function mkskill() {
    if ! command -v agentskills &> /dev/null; then
        echo "mkskill: Error - agentskills CLI not found. Install with 'brew install jwa91/tap/agentskills'." >&2
        return 1
    fi

    local repo_path="${AGENTSKILLS_REPO_PATH:-$DEV_DIR/ai-monorepo/agentskills}"
    local repo_args=()
    if [[ -n "$repo_path" && -d "$repo_path/skills" ]]; then
        repo_args=(--repo-path "$repo_path")
    elif [[ -n "${AGENTSKILLS_REPO_PATH:-}" ]]; then
        if [[ ! -d "$AGENTSKILLS_REPO_PATH/skills" ]]; then
            echo "mkskill: Error - AGENTSKILLS_REPO_PATH has no skills directory: $AGENTSKILLS_REPO_PATH" >&2
            return 1
        fi
        repo_args=(--repo-path "$AGENTSKILLS_REPO_PATH")
    else
        repo_args=(--repo-url "${AGENTSKILLS_REPO_URL:-https://github.com/jwa91/agentskills.git}")
    fi

    if [[ -n "${AGENTSKILLS_REF:-}" && -z "${AGENTSKILLS_REPO_PATH:-}" ]]; then
        repo_args+=(--ref "$AGENTSKILLS_REF")
    fi

    if [[ $# -eq 0 ]]; then
        agentskills list "${repo_args[@]}"
        return $?
    fi

    local skill_args=()
    local skill
    for skill in "$@"; do
        skill_args+=(--skill "$skill")
    done

    agentskills bootstrap --project . "${repo_args[@]}" "${skill_args[@]}" --mode copy --force
    agentskills link --project . --force
}
