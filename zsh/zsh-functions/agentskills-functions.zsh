# ----------------------------------------
# File: agentskills-functions.zsh
# Description: Helper functions for installing agent skills into projects
# Author: Jan Willem Altink
# ----------------------------------------

# --------------------------------------------------
# Function: addskill
# Description: Installs agent skills into the current project directory.
#              Without arguments, lists all available skills.
#              With a skill name, installs that skill into the current directory.
# Usage: addskill [skill-name]
# --------------------------------------------------
function addskill() {
    local AGENTSKILLS_REPO="$DEV_DIR/agentskills"
    local skills_dir="$AGENTSKILLS_REPO/skills"

    if [[ ! -d "$skills_dir" ]]; then
        echo "addskill: Error - skills directory not found: $skills_dir" >&2
        return 1
    fi

    if [[ -z "$1" ]]; then
        # List available skills
        echo "Available skills:"
        for dir in "$skills_dir"/*(N/); do
            if [[ -f "$dir/SKILL.md" ]]; then
                echo "  - ${dir:t}"
            fi
        done
        return 0
    fi

    if ! command -v agentskills &> /dev/null; then
        echo "addskill: Error - agentskills CLI not found. Run 'uv sync' in $AGENTSKILLS_REPO" >&2
        return 1
    fi

    agentskills bootstrap --project . --repo-path "$AGENTSKILLS_REPO" --skill "$1" --mode copy --force
    agentskills link --project . --force
}
