#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - PATH RESOLUTION LIBRARY
# ═══════════════════════════════════════════════════════════════════════════
#
#  Provides standardized path resolution for all scripts.
#  Source this file first to ensure consistent path handling.
#
#  Usage:
#    source lib/paths.sh
#
#  Exports:
#    OPTISCALER_ROOT     - Project root directory
#    OPTISCALER_LIB      - Library directory
#    OPTISCALER_CORE     - Core modules directory
#    OPTISCALER_SCRIPTS  - Scripts directory
#    OPTISCALER_MODULES  - Source modules directory
#    OPTISCALER_CONFIG   - Configuration directory
#    OPTISCALER_DATA     - User data directory (~/.optiscaler-universal)
#
# ═══════════════════════════════════════════════════════════════════════════

# Resolve project root only once
if [[ -z "${OPTISCALER_ROOT:-}" ]]; then
    # Determine root relative to this file's location (lib/paths.sh -> parent)
    OPTISCALER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    export OPTISCALER_ROOT
fi

# Standard directory structure
export OPTISCALER_LIB="${OPTISCALER_ROOT}/lib"
export OPTISCALER_CORE="${OPTISCALER_ROOT}/core"
export OPTISCALER_SCRIPTS="${OPTISCALER_ROOT}/scripts"
export OPTISCALER_MODULES="${OPTISCALER_ROOT}/src/modules"
export OPTISCALER_CONFIG="${OPTISCALER_ROOT}/config"
export OPTISCALER_PROFILES="${OPTISCALER_ROOT}/config/games"
export OPTISCALER_TEMPLATES="${OPTISCALER_ROOT}/templates"
export OPTISCALER_TESTS="${OPTISCALER_ROOT}/tests"

# User data directory (configurable via environment)
export OPTISCALER_DATA="${OPTISCALER_DATA_DIR:-$HOME/.optiscaler-universal}"
export OPTISCALER_CACHE="${OPTISCALER_DATA}/cache"
export OPTISCALER_LOGS="${OPTISCALER_DATA}/logs"
export OPTISCALER_BACKUPS="${OPTISCALER_DATA}/backups"
export OPTISCALER_GENERATED="${OPTISCALER_DATA}/generated"

# ───────────────────────────────────────────────────────────────────────────
# ensure_data_directories - Create all required user data directories
#
# Creates directories with mode 700 (owner only) for security
# ───────────────────────────────────────────────────────────────────────────
ensure_data_directories() {
    local dirs=(
        "$OPTISCALER_DATA"
        "$OPTISCALER_CACHE"
        "$OPTISCALER_LOGS"
        "$OPTISCALER_BACKUPS"
        "$OPTISCALER_GENERATED"
    )

    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir" 2>/dev/null || {
                echo "ERROR: Failed to create directory: $dir" >&2
                return 1
            }
            chmod 700 "$dir"
        fi
    done

    return 0
}

# ───────────────────────────────────────────────────────────────────────────
# resolve_module - Get full path to a module file
#
# Arguments:
#   $1 - Module type: "lib", "core", "src", "script"
#   $2 - Module name (without .sh extension)
#
# Returns:
#   Full path to module on stdout, or empty if not found
# ───────────────────────────────────────────────────────────────────────────
resolve_module() {
    local module_type="$1"
    local module_name="$2"
    local module_path=""

    case "$module_type" in
        lib)     module_path="${OPTISCALER_LIB}/${module_name}.sh" ;;
        core)    module_path="${OPTISCALER_CORE}/${module_name}.sh" ;;
        src)     module_path="${OPTISCALER_MODULES}/${module_name}.sh" ;;
        script)  module_path="${OPTISCALER_SCRIPTS}/${module_name}.sh" ;;
        *)
            echo "ERROR: Unknown module type: $module_type" >&2
            return 1
            ;;
    esac

    if [[ -f "$module_path" ]]; then
        echo "$module_path"
        return 0
    else
        return 1
    fi
}

# ───────────────────────────────────────────────────────────────────────────
# require_module_loaded - Verify a function from a module is available
#
# Arguments:
#   $1 - Function name to check
#   $2 - (Optional) Module name for error message
#
# Returns:
#   0 if function exists, 1 with error message otherwise
# ───────────────────────────────────────────────────────────────────────────
require_module_loaded() {
    local func_name="$1"
    local module_name="${2:-unknown}"

    if ! declare -f "$func_name" > /dev/null 2>&1; then
        echo "ERROR: Required function '$func_name' not loaded (from $module_name)" >&2
        return 1
    fi
    return 0
}

# Backward compatibility: set SCRIPT_DIR if scripts expect it
export SCRIPT_DIR="${SCRIPT_DIR:-$OPTISCALER_ROOT}"

# Export functions
export -f ensure_data_directories
export -f resolve_module
export -f require_module_loaded
