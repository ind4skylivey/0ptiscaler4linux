#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - UTILITIES LIBRARY
# ═══════════════════════════════════════════════════════════════════════════
#
#  Provides common utility functions for the OptiScaler suite.
#
#  Functions:
#    load_yaml()        - Parse YAML file to JSON
#    command_exists()   - Check if command is available
#    get_file_size()    - Get human-readable file size
#    create_backup()    - Create timestamped backup
#    verify_checksum()  - Verify SHA256 checksum
#    prompt_yes_no()    - Interactive yes/no prompt
#    sanitize_path()    - Validate and sanitize file paths
#
# ═══════════════════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────────────────
# load_yaml - Parse YAML file to JSON safely
#
# Arguments:
#   $1 - yaml_file: Path to YAML file (must exist, will be validated)
#
# Returns:
#   0 on success (outputs JSON to stdout)
#   1 on error (missing file, parse error, no python)
#
# Security:
#   Uses sys.argv to prevent command injection via filename
# ───────────────────────────────────────────────────────────────────────────
load_yaml() {
    local yaml_file="$1"

    # Input validation
    if [[ -z "$yaml_file" ]]; then
        log_error "load_yaml: No file specified"
        return 1
    fi

    # Path traversal check
    if [[ "$yaml_file" == *".."* ]]; then
        log_error "load_yaml: Path traversal detected in: $yaml_file"
        return 1
    fi

    if [[ ! -f "$yaml_file" ]]; then
        log_error "YAML file not found: $yaml_file"
        return 1
    fi

    # Ensure file is readable
    if [[ ! -r "$yaml_file" ]]; then
        log_error "YAML file not readable: $yaml_file"
        return 1
    fi

    # SECURITY: Pass filename as argument, NOT via string interpolation
    # This prevents command injection if filename contains malicious characters
    if command -v python3 &> /dev/null; then
        python3 - "$yaml_file" << 'PYSCRIPT'
import yaml
import json
import sys
import os

if len(sys.argv) < 2:
    print('{"error": "No file specified"}', file=sys.stderr)
    sys.exit(1)

filepath = sys.argv[1]

# Additional safety: resolve to absolute path and check it exists
filepath = os.path.abspath(filepath)
if not os.path.isfile(filepath):
    print(f'{{"error": "File not found: {filepath}"}}', file=sys.stderr)
    sys.exit(1)

try:
    with open(filepath, 'r', encoding='utf-8') as f:
        data = yaml.safe_load(f)
        print(json.dumps(data))
except yaml.YAMLError as e:
    print(f'{{"error": "YAML parse error: {str(e)}"}}', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'{{"error": "{str(e)}"}}', file=sys.stderr)
    sys.exit(1)
PYSCRIPT
    else
        log_warn "Python3 not found, YAML parsing limited"
        return 1
    fi
}

# ───────────────────────────────────────────────────────────────────────────
# command_exists - Check if a command is available in PATH
#
# Arguments:
#   $1 - Command name to check
#
# Returns:
#   0 if command exists, 1 otherwise
# ───────────────────────────────────────────────────────────────────────────
command_exists() {
    command -v "$1" &> /dev/null
}

# ───────────────────────────────────────────────────────────────────────────
# get_file_size - Get human-readable file size
#
# Arguments:
#   $1 - Path to file
#
# Returns:
#   Outputs size string (e.g., "4.5M") to stdout
#   "0B" if file doesn't exist
# ───────────────────────────────────────────────────────────────────────────
get_file_size() {
    local file="$1"
    if [[ -f "$file" ]]; then
        du -h "$file" | cut -f1
    else
        echo "0B"
    fi
}

# ───────────────────────────────────────────────────────────────────────────
# sanitize_path - Validate and sanitize a file path
#
# Arguments:
#   $1 - Path to validate
#   $2 - (Optional) Base directory that path must be within
#
# Returns:
#   0 if path is safe, outputs sanitized absolute path
#   1 if path is unsafe (traversal, null bytes, etc.)
#
# Security:
#   Prevents path traversal attacks
#   Rejects paths with null bytes
#   Optionally enforces path is within allowed directory
# ───────────────────────────────────────────────────────────────────────────
sanitize_path() {
    local input_path="$1"
    local allowed_base="${2:-}"

    # Reject empty paths
    if [[ -z "$input_path" ]]; then
        return 1
    fi

    # Reject paths with null bytes (security)
    if [[ "$input_path" == *$'\0'* ]]; then
        log_error "sanitize_path: Null byte detected in path"
        return 1
    fi

    # Resolve to absolute path (handles .., ., symlinks)
    local resolved_path
    resolved_path=$(realpath -m "$input_path" 2>/dev/null) || {
        log_error "sanitize_path: Failed to resolve path: $input_path"
        return 1
    }

    # If base directory specified, ensure path is within it
    if [[ -n "$allowed_base" ]]; then
        local resolved_base
        resolved_base=$(realpath -m "$allowed_base" 2>/dev/null) || return 1

        if [[ "$resolved_path" != "$resolved_base"* ]]; then
            log_error "sanitize_path: Path escapes allowed directory"
            return 1
        fi
    fi

    echo "$resolved_path"
    return 0
}

# ───────────────────────────────────────────────────────────────────────────
# create_backup - Create timestamped backup of file or directory
#
# Arguments:
#   $1 - Source file/directory to backup
#   $2 - (Optional) Backup directory (default: ~/.optiscaler-universal/backups)
#
# Returns:
#   0 on success, 1 on error
#
# Side effects:
#   Creates backup directory with mode 700 if it doesn't exist
#   Creates timestamped copy of source
# ───────────────────────────────────────────────────────────────────────────
create_backup() {
    local source="$1"
    local backup_dir="${2:-$HOME/.optiscaler-universal/backups}"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)

    # Validate source exists
    if [[ ! -e "$source" ]]; then
        log_warn "create_backup: Source does not exist: $source"
        return 1
    fi

    # Create backup directory with secure permissions
    mkdir -p "$backup_dir"
    chmod 700 "$backup_dir"

    local basename
    basename=$(basename "$source")
    local dest="$backup_dir/${basename}.${timestamp}"

    if [[ -f "$source" ]]; then
        cp "$source" "$dest" && log_info "Backed up: $source -> $dest"
    elif [[ -d "$source" ]]; then
        cp -r "$source" "$dest" && log_info "Backed up: $source -> $dest"
    fi
}

# ───────────────────────────────────────────────────────────────────────────
# verify_checksum - Verify SHA256 checksum of a file
#
# Arguments:
#   $1 - Path to file
#   $2 - Expected SHA256 hash (64 hex characters)
#
# Returns:
#   0 if checksum matches, 1 otherwise
# ───────────────────────────────────────────────────────────────────────────
verify_checksum() {
    local file="$1"
    local expected_hash="$2"

    # Validate inputs
    if [[ ! -f "$file" ]]; then
        log_error "verify_checksum: File not found: $file"
        return 1
    fi

    if [[ ! "$expected_hash" =~ ^[a-fA-F0-9]{64}$ ]]; then
        log_error "verify_checksum: Invalid hash format (expected 64 hex chars)"
        return 1
    fi

    local actual_hash
    actual_hash=$(sha256sum "$file" | cut -d' ' -f1)

    # Case-insensitive comparison
    if [[ "${expected_hash,,}" == "${actual_hash,,}" ]]; then
        return 0
    else
        log_error "Checksum mismatch for $file"
        log_error "Expected: $expected_hash"
        log_error "Got:      $actual_hash"
        return 1
    fi
}

# ───────────────────────────────────────────────────────────────────────────
# prompt_yes_no - Interactive yes/no prompt
#
# Arguments:
#   $1 - Prompt message
#   $2 - (Optional) Default answer: "y" or "n" (default: "n")
#
# Returns:
#   0 if user answered yes, 1 if no
#
# Notes:
#   - Accepts Y/y/yes/Yes for yes, N/n/no/No for no
#   - Empty input uses default
#   - Loops until valid input received
# ───────────────────────────────────────────────────────────────────────────
prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"

    # Validate default
    case "$default" in
        [Yy]*) default="y" ;;
        *)     default="n" ;;
    esac

    while true; do
        if [[ "$default" == "y" ]]; then
            read -r -p "$prompt [Y/n]: " REPLY
        else
            read -r -p "$prompt [y/N]: " REPLY
        fi

        # Use default if empty
        if [[ -z "$REPLY" ]]; then
            REPLY="$default"
        fi

        case "$REPLY" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo])     return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

# ───────────────────────────────────────────────────────────────────────────
# ensure_dir_secure - Create directory with secure permissions
#
# Arguments:
#   $1 - Directory path to create
#   $2 - (Optional) Permissions mode (default: 700)
#
# Returns:
#   0 on success, 1 on failure
# ───────────────────────────────────────────────────────────────────────────
ensure_dir_secure() {
    local dir="$1"
    local mode="${2:-700}"

    if [[ -z "$dir" ]]; then
        log_error "ensure_dir_secure: No directory specified"
        return 1
    fi

    if ! mkdir -p "$dir" 2>/dev/null; then
        log_error "Failed to create directory: $dir"
        return 1
    fi

    chmod "$mode" "$dir"
}

# Export functions
export -f load_yaml
export -f command_exists
export -f get_file_size
export -f sanitize_path
export -f create_backup
export -f verify_checksum
export -f prompt_yes_no
export -f ensure_dir_secure
