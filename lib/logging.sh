#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - LOGGING LIBRARY
# ═══════════════════════════════════════════════════════════════════════════
#
#  Provides comprehensive logging functionality
#
#  Usage: source lib/logging.sh
#
# ═══════════════════════════════════════════════════════════════════════════

# Configuration
LOG_DIR="${HOME}/.optiscaler-universal/logs"
LOG_FILE="${LOG_DIR}/optiscaler-$(date +%Y%m%d).log"
LOG_LEVEL="${LOG_LEVEL:-INFO}"  # TRACE, DEBUG, INFO, WARN, ERROR
LOG_TO_FILE="${LOG_TO_FILE:-true}"
LOG_TO_CONSOLE="${LOG_TO_CONSOLE:-true}"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Log levels
declare -A LOG_LEVELS=(
    [TRACE]=0
    [DEBUG]=1
    [INFO]=2
    [WARN]=3
    [ERROR]=4
)

# Current log level (default INFO/2 if unknown)
CURRENT_LOG_LEVEL=${LOG_LEVELS[$LOG_LEVEL]:-2}

# ═══════════════════════════════════════════════════════════════════════════
#  Core Logging Functions
# ═══════════════════════════════════════════════════════════════════════════

_log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] [$level] $message"
    
    # Check if we should log this level
    local level_value=${LOG_LEVELS[$level]:-2}
    if [ "$level_value" -lt "${CURRENT_LOG_LEVEL:-2}" ]; then
        return 0
    fi
    
    # Log to file
    if [ "$LOG_TO_FILE" = "true" ]; then
        echo "$log_entry" >> "$LOG_FILE"
    fi
    
    # Log to console with colors
    if [ "$LOG_TO_CONSOLE" = "true" ]; then
        local color=""
        case "$level" in
            TRACE)  color="\033[0;37m" ;;  # Gray
            DEBUG)  color="\033[0;36m" ;;  # Cyan
            INFO)   color="\033[0;32m" ;;  # Green
            WARN)   color="\033[1;33m" ;;  # Yellow
            ERROR)  color="\033[0;31m" ;;  # Red
        esac
        
        echo -e "${color}[$level]${NC} $message" >&2
    fi
}

log_trace() {
    _log "TRACE" "$@"
}

log_debug() {
    _log "DEBUG" "$@"
}

log_info() {
    _log "INFO" "$@"
}

log_warn() {
    _log "WARN" "$@"
}

log_error() {
    _log "ERROR" "$@"
}

# ═══════════════════════════════════════════════════════════════════════════
#  Specialized Logging Functions
# ═══════════════════════════════════════════════════════════════════════════

log_success() {
    local message="$*"
    echo -e "${GREEN}✓${NC} $message"
    _log "INFO" "SUCCESS: $message"
}

log_failure() {
    local message="$*"
    echo -e "${RED}✗${NC} $message"
    _log "ERROR" "FAILURE: $message"
}

log_step() {
    local step_num="$1"
    local total_steps="$2"
    shift 2
    local message="$*"
    echo -e "${BLUE}→ Step $step_num/$total_steps:${NC} $message"
    _log "INFO" "STEP [$step_num/$total_steps]: $message"
}

log_section() {
    local title="$*"
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $title${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    _log "INFO" "SECTION: $title"
}

log_command() {
    local command="$*"
    log_debug "Executing: $command"
    _log "DEBUG" "CMD: $command"
}

# ═══════════════════════════════════════════════════════════════════════════
#  Progress Logging
# ═══════════════════════════════════════════════════════════════════════════

log_progress() {
    local current="$1"
    local total="$2"
    local message="$3"
    local percentage=$((current * 100 / total))
    
    echo -ne "\r${CYAN}[$current/$total - ${percentage}%]${NC} $message                    "
    
    if [ "$current" -eq "$total" ]; then
        echo ""  # New line when complete
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  Error Handling
# ═══════════════════════════════════════════════════════════════════════════

log_error_exit() {
    local message="$*"
    log_error "$message"
    log_error "Installation failed. Check log file: $LOG_FILE"
    exit 1
}

log_error_with_trace() {
    local message="$*"
    log_error "$message"
    log_error "Call stack:"
    
    local frame=0
    while caller $frame; do
        ((frame++))
    done | while read line func file; do
        log_error "  at $func ($file:$line)"
    done
}

# ═══════════════════════════════════════════════════════════════════════════
#  Log Management
# ═══════════════════════════════════════════════════════════════════════════

cleanup_old_logs() {
    local days="${1:-7}"  # Keep logs for 7 days by default
    
    log_debug "Cleaning up log files older than $days days"
    
    find "$LOG_DIR" -name "optiscaler-*.log" -type f -mtime "+$days" -delete
}

get_log_file_path() {
    echo "$LOG_FILE"
}

show_recent_errors() {
    local count="${1:-10}"
    
    if [ -f "$LOG_FILE" ]; then
        echo "Recent errors:"
        grep "\[ERROR\]" "$LOG_FILE" | tail -n "$count"
    else
        echo "No log file found"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  Initialization
# ═══════════════════════════════════════════════════════════════════════════

_init_logging() {
    # Source colors if not already loaded
    if [ -z "$NC" ]; then
        source "$(dirname "${BASH_SOURCE[0]}")/colors.sh" 2>/dev/null || true
    fi
    
    # Log initialization
    log_debug "Logging initialized"
    log_debug "Log file: $LOG_FILE"
    log_debug "Log level: $LOG_LEVEL"
    
    # Clean up old logs
    cleanup_old_logs
}

# Initialize on source
_init_logging

# Export functions
export -f log_trace
export -f log_debug
export -f log_info
export -f log_warn
export -f log_error
export -f log_success
export -f log_failure
export -f log_step
export -f log_section
export -f log_command
export -f log_progress
export -f log_error_exit
export -f log_error_with_trace
export -f cleanup_old_logs
export -f get_log_file_path
export -f show_recent_errors
