#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - MAIN INSTALLER (SECURITY HARDENED)
# ═══════════════════════════════════════════════════════════════════════════
#
#  Automatically configures OptiScaler for Steam games on Linux.
#
#  Features:
#    - Multi-disk Steam library detection
#    - GPU auto-detection (AMD, Intel, NVIDIA)
#    - Profile-based game configuration
#    - Automatic backup before installation
#
#  Security improvements:
#    - No automatic sudo execution
#    - Proper input validation
#    - Safe temporary file handling
#    - Proper error handling
#
# ═══════════════════════════════════════════════════════════════════════════

set -eo pipefail

# ═══════════════════════════════════════════════════════════════════════════
#  CONSTANTS & CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════

readonly VERSION="1.0.0"
readonly LICENSE="MIT - Open Source"
readonly SCRIPT_NAME="OptiScaler Universal Installer"

# Resolve script directory (handles symlinks)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly SCRIPT_DIR
readonly MODULE_DIR="$SCRIPT_DIR/src/modules"
readonly CORE_DIR="$SCRIPT_DIR/core"
readonly LIB_DIR="$SCRIPT_DIR/lib"

# Runtime configuration (can be overridden by environment)
LOG_LEVEL="${LOG_LEVEL:-INFO}"
VERBOSE_MODE=false
DEBUG_MODE=false
SCAN_ONLY=false
LIST_GAMES=false
FORCE_RESCAN=false
AUTO_PROFILE_UNKNOWN="${AUTO_PROFILE_UNKNOWN:-false}"
SKIP_PROFILE_UNKNOWN="${SKIP_PROFILE_UNKNOWN:-false}"
DELIM=$'\x1f'

# ═══════════════════════════════════════════════════════════════════════════
#  UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

# Print banner with version info
print_banner() {
    cat << 'BANNER'

═══════════════════════════════════════════════════════════════════════════

                    OPTISCALER UNIVERSAL INSTALLER

           Unlock your GPU's full potential on Linux - automatically

═══════════════════════════════════════════════════════════════════════════

BANNER
    echo "Version: $VERSION"
    echo "License: $LICENSE"
    echo ""
}

# Display usage information
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --verbose               Enable verbose logging (DEBUG level)
  --debug                 Enable maximum logging (TRACE level)
  --list-games            List supported games and exit
  --scan-only             Scan Steam libraries without installing
  --force-rescan          Ignore cache and rescan libraries
  --auto-profile-unknown  Auto-generate profiles for unknown games
  --skip-profile-unknown  Skip unknown games without prompting
  -h, --help              Show this help message

Environment Variables:
  LOG_LEVEL               Set log level: TRACE, DEBUG, INFO, WARN, ERROR
  OPTISCALER_STEAM_HINTS  Colon-separated list of additional Steam paths
  OPTISCALER_DATA_DIR     Override data directory (~/.optiscaler-universal)

Examples:
  $(basename "$0") --scan-only
  $(basename "$0") --verbose --force-rescan
  OPTISCALER_STEAM_HINTS="/mnt/games/Steam" $(basename "$0")

EOF
}

# Parse command-line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose)
                LOG_LEVEL="DEBUG"
                VERBOSE_MODE=true
                ;;
            --debug)
                LOG_LEVEL="TRACE"
                DEBUG_MODE=true
                ;;
            --list-games)
                LIST_GAMES=true
                ;;
            --scan-only)
                SCAN_ONLY=true
                ;;
            --force-rescan)
                FORCE_RESCAN=true
                ;;
            --auto-profile-unknown)
                AUTO_PROFILE_UNKNOWN=true
                ;;
            --skip-profile-unknown)
                SKIP_PROFILE_UNKNOWN=true
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                echo "ERROR: Unknown option: $1" >&2
                echo "Use --help for usage information." >&2
                exit 1
                ;;
            *)
                echo "ERROR: Unexpected argument: $1" >&2
                echo "Use --help for usage information." >&2
                exit 1
                ;;
        esac
        shift
    done

    # Export for child processes
    export LOG_LEVEL VERBOSE_MODE DEBUG_MODE FORCE_RESCAN
}

# ═══════════════════════════════════════════════════════════════════════════
#  MODULE LOADING
# ═══════════════════════════════════════════════════════════════════════════

# Verify a required function is loaded
require_function() {
    local func_name="$1"
    local module_name="${2:-unknown}"

    if ! declare -f "$func_name" > /dev/null; then
        echo "ERROR: Required function '$func_name' not loaded (from $module_name)" >&2
        return 1
    fi
    return 0
}

# Load library modules (colors, logging, utils)
load_lib_modules() {
    local required_libs=("colors.sh" "logging.sh" "utils.sh")

    for lib in "${required_libs[@]}"; do
        local lib_path="$LIB_DIR/$lib"
        if [[ -f "$lib_path" ]]; then
            # shellcheck source=/dev/null
            source "$lib_path" || {
                echo "ERROR: Failed to load library: $lib" >&2
                return 1
            }
        else
            echo "ERROR: Library not found: $lib_path" >&2
            return 1
        fi
    done

    return 0
}

# Load source modules (parsers, detectors)
load_src_modules() {
    log_section "Loading source modules"

    local modules=("steam_parser.sh" "game_detector.sh")

    for module in "${modules[@]}"; do
        local module_path="$MODULE_DIR/$module"
        if [[ -f "$module_path" ]]; then
            # shellcheck source=/dev/null
            source "$module_path" || {
                log_warn "Module loaded with warnings: $module"
            }
            log_success "Loaded: $module"
        else
            log_error "Module not found: $module_path"
            return 1
        fi
    done

    return 0
}

# Load core modules (downloader, detector)
load_core_modules() {
    log_section "Loading core modules"

    local modules=("downloader.sh")

    for module in "${modules[@]}"; do
        local module_path="$CORE_DIR/$module"
        if [[ -f "$module_path" ]]; then
            # shellcheck source=/dev/null
            source "$module_path" || {
                log_warn "Core module loaded with warnings: $module"
            }
            log_success "Loaded: ${module%.sh}"
        else
            log_warn "Core module not found: $module_path"
        fi
    done

    return 0
}

# ═══════════════════════════════════════════════════════════════════════════
#  PHASE 1: SYSTEM REQUIREMENTS
# ═══════════════════════════════════════════════════════════════════════════

check_requirements() {
    log_section "Checking System Requirements"

    local required_commands=("lspci" "sed" "awk" "grep" "wget" "unzip" "tar" "curl")
    local missing_commands=()

    for cmd in "${required_commands[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            log_success "$cmd: found"
        else
            log_error "$cmd: NOT FOUND"
            missing_commands+=("$cmd")
        fi
    done

    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error ""
        log_error "Missing required commands: ${missing_commands[*]}"
        log_error "Please install them using your package manager."
        return 1
    fi

    log_success "All requirements met"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════
#  PHASE 2: GPU DETECTION
# ═══════════════════════════════════════════════════════════════════════════

detect_gpu() {
    log_section "Detecting GPU Configuration"

    local gpu_info
    gpu_info=$(lspci 2>/dev/null | grep -i "VGA\|3D" | head -1) || true

    if [[ -z "$gpu_info" ]]; then
        log_warn "No GPU detected via lspci"
        GPU_VENDOR="UNKNOWN"
        return 1
    fi

    log_info "GPU Info: $gpu_info"

    if echo "$gpu_info" | grep -qi "AMD\|Radeon"; then
        GPU_VENDOR="AMD"
        log_success "GPU Vendor: AMD"
    elif echo "$gpu_info" | grep -qi "NVIDIA"; then
        GPU_VENDOR="NVIDIA"
        log_success "GPU Vendor: NVIDIA"
    elif echo "$gpu_info" | grep -qi "Intel"; then
        GPU_VENDOR="Intel"
        log_success "GPU Vendor: Intel"
    else
        GPU_VENDOR="UNKNOWN"
        log_warn "GPU Vendor: UNKNOWN"
    fi

    export GPU_VENDOR
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════
#  PHASE 3: DOWNLOAD DEPENDENCIES
# ═══════════════════════════════════════════════════════════════════════════

download_deps() {
    log_section "Downloading Dependencies"

    # Verify download functions are available
    if ! require_function "download_optiscaler" "core/downloader.sh"; then
        log_error "Download module not properly loaded"
        return 1
    fi

    if ! download_optiscaler; then
        log_error "Failed to download OptiScaler"
        return 1
    fi

    if declare -f download_fakenvapi > /dev/null; then
        if ! download_fakenvapi; then
            log_warn "Failed to download fakenvapi (may not be required)"
        fi
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════════════════
#  PHASE 4: SCAN STEAM LIBRARIES
# ═══════════════════════════════════════════════════════════════════════════

scan_steam_libraries() {
    log_section "Scanning Steam libraries (multi-disk)"

    if ! require_function "discover_steam_libraries" "game_detector.sh"; then
        return 1
    fi

    discover_steam_libraries

    if [[ ${#STEAM_LIBRARIES[@]} -eq 0 ]]; then
        log_error "No Steam libraries found!"
        log_info ""
        log_info "Tips:"
        log_info "  - Make sure Steam is installed"
        log_info "  - Set OPTISCALER_STEAM_HINTS environment variable"
        log_info "  - Example: OPTISCALER_STEAM_HINTS=\"/mnt/games/Steam\""
        return 1
    fi

    log_success "Detected ${#STEAM_LIBRARIES[@]} Steam library location(s):"
    for lib in "${STEAM_LIBRARIES[@]}"; do
        log_info "  ├─ $lib"
    done

    return 0
}

# ═══════════════════════════════════════════════════════════════════════════
#  PHASE 5: GAME DETECTION
# ═══════════════════════════════════════════════════════════════════════════

scan_games() {
    log_section "Detecting installed games (multi-method)"

    if ! require_function "detect_all_games" "game_detector.sh"; then
        return 1
    fi

    detect_all_games
    GAMES_FOUND_COUNT=${#DETECTED_GAMES[@]}

    if require_function "print_detected_games_table" "game_detector.sh"; then
        print_detected_games_table
    fi

    log_success "Detection finished: $GAMES_FOUND_COUNT compatible game(s)"
    return 0
}

# Generate profiles for unknown games
maybe_generate_generic_profiles() {
    local unsupported_count=${#DETECTED_UNSUPPORTED[@]}
    (( unsupported_count == 0 )) && return 0

    # Helper to prompt booleans with default
    _prompt_bool() {
        local question="$1"
        local default="${2:-y}"
        local answer
        local prompt

        if [[ "$default" =~ ^[Yy]$ ]]; then
            prompt="[Y/n]"
        else
            prompt="[y/N]"
        fi

        echo -n "$question $prompt "
        read -r answer
        [[ -z "$answer" ]] && answer="$default"
        [[ "$answer" =~ ^[Yy]$ ]] && return 0 || return 1
    }

    # Filter unsupported entries that have an AppID
    local -a creatable=()
    local rec app_id
    for rec in "${DETECTED_UNSUPPORTED[@]}"; do
        app_id="$(echo "$rec" | tr "$DELIM" '\n' | awk -F= '$1=="app_id"{print $2}' | head -1)"
        [[ -n "$app_id" ]] && creatable+=("$rec")
    done

    (( ${#creatable[@]} == 0 )) && {
        log_info "Unsupported items lack AppID; no generic profiles created."
        return 0
    }

    local games_dir="$SCRIPT_DIR/config/games"
    mkdir -p "$games_dir"

    for rec in "${creatable[@]}"; do
        local game_name app_id install_path method
        IFS="$DELIM" read -r -a kvs <<< "$rec"
        for kv in "${kvs[@]}"; do
            local k="${kv%%=*}"
            local v="${kv#*=}"
            case "$k" in
                game_name) game_name="$v" ;;
                app_id) app_id="$v" ;;
                install_path) install_path="$v" ;;
                detection_method) method="$v" ;;
            esac
        done
        [[ -z "$app_id" || -z "$install_path" ]] && continue

        local do_create="n"
        if $SKIP_PROFILE_UNKNOWN; then
            do_create="n"
        elif $AUTO_PROFILE_UNKNOWN; then
            do_create="y"
        else
            echo ""
            echo "Create generic profile for \"$game_name\" (AppID: $app_id)? [y/N]"
            read -r do_create
        fi
        [[ ! "$do_create" =~ ^[Yy] ]] && { log_info "Skipped $game_name ($app_id)"; continue; }

        local base
        base="$(basename "$install_path")"
        local game_id
        game_id="$(echo "$base" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-*//;s/-*$//')"
        [[ -z "$game_id" ]] && game_id="game-$app_id"

        local profile_file="$games_dir/$game_id.yaml"
        if [[ -f "$profile_file" ]]; then
            log_info "Profile already exists for $game_name ($app_id), skipping."
            continue
        fi

        # Component selection defaults
        local install_optiscaler=true
        local install_xess=true
        local install_fakenvapi=false
        [[ "${GPU_VENDOR:-}" =~ ^(AMD|Intel)$ ]] && install_fakenvapi=true
        local preset="balanced"
        local dlss_to_fsr=true

        if ! $AUTO_PROFILE_UNKNOWN && ! $SKIP_PROFILE_UNKNOWN; then
            _prompt_bool "Install OptiScaler DLL replacement?" "y" && install_optiscaler=true || install_optiscaler=false
            _prompt_bool "Install XeSS runtime (libxess.dll)?" "y" && install_xess=true || install_xess=false
            local fakedef="n"
            [[ "${GPU_VENDOR:-}" =~ ^(AMD|Intel)$ ]] && fakedef="y"
            _prompt_bool "Install fakenvapi (NVAPI shim)?" "$fakedef" && install_fakenvapi=true || install_fakenvapi=false
            echo -n "Choose OptiScaler preset [quality/balanced/performance/ultra-performance] (default: balanced): "
            read -r preset
            [[ -z "$preset" ]] && preset="balanced"
            _prompt_bool "Enable DLSS->FSR translation (dlss_to_fsr)?" "y" && dlss_to_fsr=true || dlss_to_fsr=false
        fi

        cat > "$profile_file" << EOF
# Auto-generated generic profile. Please refine executables/dll_targets.
game_id: $game_id
name: "$game_name"
app_id: $app_id

detection:
  folder_patterns:
    - "$base"
    - "$game_name"
  executables: []
  required_files: []
  dll_targets:
    - "bin"
    - "Binaries/Win64"
    - "."

components:
  install_optiscaler: $install_optiscaler
  install_xess: $install_xess
  install_fakenvapi: $install_fakenvapi

optiscaler:
  preset: "$preset"
  dlss_to_fsr: $dlss_to_fsr
EOF
        log_success "Generated generic profile: $profile_file (from $method)"
    done

    # Re-run detection to include new profiles
    FORCE_RESCAN=true
    detect_all_games
    GAMES_FOUND_COUNT=${#DETECTED_GAMES[@]}
    print_detected_games_table
    log_success "Detection re-run after generating generic profiles: $GAMES_FOUND_COUNT compatible game(s)"
}

# ═══════════════════════════════════════════════════════════════════════════
#  PHASE 6: INSTALL
# ═══════════════════════════════════════════════════════════════════════════

do_install() {
    log_section "Installing OptiScaler to Found Games"

    if [[ ${GAMES_FOUND_COUNT:-0} -eq 0 ]]; then
        log_warn "No games found to install"
        return 0
    fi

    # Verify install function is available
    if ! require_function "install_to_game" "core/downloader.sh"; then
        log_error "Install function not available"
        return 1
    fi

    local games_installed=0
    local games_failed=0

    for rec in "${DETECTED_GAMES[@]}"; do
        local app_id="" game_path="" game_name="" profile_path="" dll_target_dir=""

        IFS="$DELIM" read -r -a kvs <<< "$rec"
        for kv in "${kvs[@]}"; do
            local key="${kv%%=*}"
            local val="${kv#*=}"
            case "$key" in
                app_id) app_id="$val" ;;
                install_path) game_path="$val" ;;
                game_name) game_name="$val" ;;
                profile_matched) profile_path="$val" ;;
                dll_target_dir) dll_target_dir="$val" ;;
            esac
        done

        log_info "Installing to: $game_name ($app_id)"

        if install_to_game "$game_path" "$app_id" "$profile_path" "$dll_target_dir"; then
            ((games_installed++)) || true
        else
            ((games_failed++)) || true
            log_warn "Failed to install to: $game_name"
        fi
    done

    log_success "Installation complete: $games_installed/${GAMES_FOUND_COUNT} game(s) updated"

    if [[ $games_failed -gt 0 ]]; then
        log_warn "$games_failed game(s) failed installation"
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════════════════
#  FINAL REPORT
# ═══════════════════════════════════════════════════════════════════════════

final_report() {
    log_section "Installation Summary"

    log_info "GPU Detected: ${GPU_VENDOR:-UNKNOWN}"
    log_info "Steam Libraries: ${#STEAM_LIBRARIES[@]} found"
    log_info "Games Updated: ${GAMES_FOUND_COUNT:-0}"
    log_info ""
    log_info "Next Steps:"
    log_info "  1. Launch your game from Steam"
    log_info "  2. Enable DLSS/FSR in graphics settings"
    log_info "  3. OptiScaler will automatically intercept and use FSR"
    log_info ""
    log_info "Troubleshooting:"
    log_info "  - Run: optiscaler-diagnose --game-dir <path>"
    log_info "  - Check game logs: ~/.optiscaler-universal/logs/"
    log_info ""
    log_section "Installation Complete!"
}

# ═══════════════════════════════════════════════════════════════════════════
#  ERROR HANDLER
# ═══════════════════════════════════════════════════════════════════════════

error_handler() {
    local line_no="$1"
    local error_code="${2:-1}"

    echo "" >&2
    echo "ERROR: Script failed at line $line_no (exit code: $error_code)" >&2

    if [[ -n "${LOG_FILE:-}" && -f "${LOG_FILE:-}" ]]; then
        echo "Check log file for details: $LOG_FILE" >&2
    fi

    exit "$error_code"
}

# Set up error trap
trap 'error_handler $LINENO $?' ERR

# ═══════════════════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════════════════

main() {
    # Load libraries first (needed for argument parsing error messages)
    if ! load_lib_modules; then
        echo "FATAL: Failed to load library modules" >&2
        exit 1
    fi

    # Parse command-line arguments
    parse_args "$@"

    # Update logging level after argument parsing
    if [[ -n "${LOG_LEVELS[$LOG_LEVEL]:-}" ]]; then
        CURRENT_LOG_LEVEL=${LOG_LEVELS[$LOG_LEVEL]}
    else
        CURRENT_LOG_LEVEL=${LOG_LEVELS[INFO]:-2}
    fi

    print_banner
    log_info "Starting $SCRIPT_NAME..."

    # Load remaining modules
    if ! load_src_modules; then
        log_error_exit "Failed to load source modules"
    fi

    if ! load_core_modules; then
        log_error_exit "Failed to load core modules"
    fi

    # Phase 1: Check requirements
    if ! check_requirements; then
        log_error_exit "System requirements not met"
    fi

    # Phase 2: Detect GPU
    detect_gpu || true  # Continue even if GPU detection fails

    # Phase 3: Download dependencies
    if ! download_deps; then
        log_error_exit "Failed to download dependencies"
    fi

    # Phase 4: Scan Steam libraries
    if ! scan_steam_libraries; then
        log_error_exit "Failed to scan Steam libraries"
    fi

    # Phase 5: Detect games
    if ! scan_games; then
        log_error_exit "Failed to detect games"
    fi

    # Generate profiles for unknown games if requested
    maybe_generate_generic_profiles

    # Handle special modes
    if $LIST_GAMES; then
        log_section "Supported Games"
        if require_function "list_supported_games" "game_detector.sh"; then
            list_supported_games
        fi
        exit 0
    fi

    if $SCAN_ONLY; then
        log_info "Scan-only mode requested; exiting."
        exit 0
    fi

    # Phase 6: Install to games
    do_install

    # Final report
    final_report
}

# Run main function with all arguments
main "$@"
