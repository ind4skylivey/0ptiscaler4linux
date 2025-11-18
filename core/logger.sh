#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - LOGGER MODULE
# ═══════════════════════════════════════════════════════════════════════════
#
#  Provides colored logging functions for the entire system
#
# ═══════════════════════════════════════════════════════════════════════════

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ═══════════════════════════════════════════════════════════════════════════
#  LOGGING FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

log_info() {
    echo -e "${CYAN}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓ [SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}⚠ [WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}✗ [ERROR]${NC} $*" >&2
}

log_error_exit() {
    echo -e "${RED}✗ [ERROR]${NC} $*" >&2
    exit 1
}

log_section() {
    echo ""
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}  $*${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

log_subsection() {
    echo -e "${BLUE}>>> $*${NC}"
}

log_debug() {
    if [[ "$DEBUG_MODE" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $*"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  EXPORT FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

export -f log_info
export -f log_success
export -f log_warn
export -f log_error
export -f log_error_exit
export -f log_section
export -f log_subsection
export -f log_debug

