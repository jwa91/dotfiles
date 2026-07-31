#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_section() { echo -e "\n${BLUE}--- $1 ---${NC}"; }
log_skip() { echo -e "${GREEN}SKIP:${NC} $1"; }
log_action() {
    if $DRY_RUN; then
        echo -e "${YELLOW}WOULD:${NC} $1"
    else
        echo -e "${YELLOW}DO:${NC} $1"
    fi
}
log_warn() { echo -e "${YELLOW}WARN:${NC} $1"; }
log_error() { echo -e "${RED}ERROR:${NC} $1"; }
