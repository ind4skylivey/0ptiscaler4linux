#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - COLORS LIBRARY
# ═══════════════════════════════════════════════════════════════════════════
#
#  Provides color definitions for terminal output
#
#  Usage: source lib/colors.sh
#
# ═══════════════════════════════════════════════════════════════════════════

# Check if colors are supported
if [ -t 1 ]; then
    # Regular colors
    export BLACK='\033[0;30m'
    export RED='\033[0;31m'
    export GREEN='\033[0;32m'
    export YELLOW='\033[0;33m'
    export BLUE='\033[0;34m'
    export MAGENTA='\033[0;35m'
    export CYAN='\033[0;36m'
    export WHITE='\033[0;37m'
    
    # Bold colors
    export BOLD_BLACK='\033[1;30m'
    export BOLD_RED='\033[1;31m'
    export BOLD_GREEN='\033[1;32m'
    export BOLD_YELLOW='\033[1;33m'
    export BOLD_BLUE='\033[1;34m'
    export BOLD_MAGENTA='\033[1;35m'
    export BOLD_CYAN='\033[1;36m'
    export BOLD_WHITE='\033[1;37m'
    
    # Background colors
    export BG_BLACK='\033[40m'
    export BG_RED='\033[41m'
    export BG_GREEN='\033[42m'
    export BG_YELLOW='\033[43m'
    export BG_BLUE='\033[44m'
    export BG_MAGENTA='\033[45m'
    export BG_CYAN='\033[46m'
    export BG_WHITE='\033[47m'
    
    # No color (reset)
    export NC='\033[0m'
    
    # Special formatting
    export BOLD='\033[1m'
    export DIM='\033[2m'
    export ITALIC='\033[3m'
    export UNDERLINE='\033[4m'
    export BLINK='\033[5m'
    export REVERSE='\033[7m'
    export HIDDEN='\033[8m'
else
    # No color support
    export BLACK=''
    export RED=''
    export GREEN=''
    export YELLOW=''
    export BLUE=''
    export MAGENTA=''
    export CYAN=''
    export WHITE=''
    export BOLD_BLACK=''
    export BOLD_RED=''
    export BOLD_GREEN=''
    export BOLD_YELLOW=''
    export BOLD_BLUE=''
    export BOLD_MAGENTA=''
    export BOLD_CYAN=''
    export BOLD_WHITE=''
    export BG_BLACK=''
    export BG_RED=''
    export BG_GREEN=''
    export BG_YELLOW=''
    export BG_BLUE=''
    export BG_MAGENTA=''
    export BG_CYAN=''
    export BG_WHITE=''
    export NC=''
    export BOLD=''
    export DIM=''
    export ITALIC=''
    export UNDERLINE=''
    export BLINK=''
    export REVERSE=''
    export HIDDEN=''
fi

# Helper functions
colorize() {
    local color="$1"
    shift
    echo -e "${color}${*}${NC}"
}

colorize_bold() {
    local color="$1"
    shift
    echo -e "${BOLD}${color}${*}${NC}"
}
