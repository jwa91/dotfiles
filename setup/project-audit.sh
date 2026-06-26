#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
# shellcheck disable=SC2034 # Consumed by setup/lib/logging.sh.
DRY_RUN=false

# shellcheck source=setup/lib/logging.sh
# shellcheck disable=SC1091
source "$LIB_DIR/logging.sh"
# shellcheck source=setup/lib/paths.sh
# shellcheck disable=SC1091
source "$LIB_DIR/paths.sh"
# shellcheck source=setup/lib/project_audit.sh
# shellcheck disable=SC1091
source "$LIB_DIR/project_audit.sh"

project_audit "$@"
