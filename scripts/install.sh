#!/bin/bash

# =============================================================================
#  OPTISCALER UNIVERSAL - MAIN INSTALLER (ROBUST VERSION)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE_DIR="$SCRIPT_DIR/src/modules"
VERSION="0.1.0-alpha"
LICENSE="MIT - Open Source"

LOG_LEVEL="${LOG_LEVEL:-INFO}"
VERBOSE_MODE=false
DEBUG_MODE=false
SCAN_ONLY=false
LIST_GAMES=false
FORCE_RESCAN=false

# =============================================================================
#  MODULE LOADING
# =============================================================================

print_banner() {
    cat << "EOF"

═══════════════════════════════════════════════════════════════════════════

                    OPTISCALER UNIVERSAL INSTALLER                        
                                                                           
           Unlock your GPU's full potential on Linux - automatically      
                                                                           
═══════════════════════════════════════════════════════════════════════════

EOF
    echo "Version: $VERSION"
    echo "License: $LICENSE"
    echo ""
}

load_modules() {
    source "$SCRIPT_DIR/lib/colors.sh"
    source "$SCRIPT_DIR/lib/logging.sh"
    source "$MODULE_DIR/steam_parser.sh"
    source "$MODULE_DIR/game_detector.sh"
}

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]
  --verbose           Verbose logging (DEBUG)
  --debug             Max logging (TRACE) with disk/mount details
  --list-games        List supported games (profiles) and exit
  --scan-only         Scan Steam libraries without installing
  --force-rescan      Ignore cache and rescan libraries
  -h, --help          Show this help
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose) LOG_LEVEL="DEBUG"; VERBOSE_MODE=true ;;
            --debug) LOG_LEVEL="TRACE"; DEBUG_MODE=true ;;
            --list-games) LIST_GAMES=true ;;
            --scan-only) SCAN_ONLY=true ;;
            --force-rescan) FORCE_RESCAN=true ;;
            -h|--help) usage; exit 0 ;;
            *) log_warn "Unknown option: $1"; usage; exit 1 ;;
        esac
        shift
    done
    export LOG_LEVEL VERBOSE_MODE DEBUG_MODE FORCE_RESCAN
}

# ═══════════════════════════════════════════════════════════════════════════
#  MODULE LOADING (With error handling)
# ═══════════════════════════════════════════════════════════════════════════

print_banner() {
    cat << "EOF"

═══════════════════════════════════════════════════════════════════════════

                    OPTISCALER UNIVERSAL INSTALLER                        
                                                                           
           Unlock your GPU's full potential on Linux - automatically      
                                                                           
═══════════════════════════════════════════════════════════════════════════

Version: 0.1.0-alpha
License: MIT - Open Source

EOF
}

load_core_modules() {
    log_section "Loading core modules"
    local modules=("downloader" "steam_scan")
    for module in "${modules[@]}"; do
        local module_path="$SCRIPT_DIR/core/${module}.sh"
        [[ -f "$module_path" ]] || { log_warn "Module not found: $module_path"; continue; }
        source "$module_path" 2>/dev/null || log_warn "Loaded $module with warnings"
        log_success "Loaded: $module"
    done
}

# =============================================================================
#  PHASE 1: SYSTEM REQUIREMENTS
# =============================================================================

check_requirements() {
    log_section "Checking System Requirements"
    
    local required_commands=("lspci" "sed" "awk" "grep" "wget" "unzip" "tar" "curl")
    local all_ok=true
    
    for cmd in "${required_commands[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            log_success "$cmd: found"
        else
            log_error "$cmd: NOT FOUND"
            all_ok=false
        fi
    done
    
    [[ "$all_ok" == false ]] && log_error_exit "Missing required commands"
    log_success "All requirements met"
}

# ═══════════════════════════════════════════════════════════════════════════
#  PHASE 2: GPU DETECTION
# ═══════════════════════════════════════════════════════════════════════════

detect_gpu() {
    log_section "Detecting GPU Configuration"
    
    local gpu_info=$(lspci 2>/dev/null | grep -i "VGA\|3D" | head -1)
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
}

# ═══════════════════════════════════════════════════════════════════════════
#  PHASE 3: DOWNLOAD DEPENDENCIES
# ═══════════════════════════════════════════════════════════════════════════

download_deps() {
    log_section "Downloading Dependencies"
    
    if declare -f download_optiscaler >/dev/null; then
        download_optiscaler || log_error_exit "Failed to download OptiScaler"
    else
        log_warn "download_optiscaler function not available"
    fi
    
    if declare -f download_fakenvapi >/dev/null; then
        download_fakenvapi || log_error_exit "Failed to download fakenvapi"
    else
        log_warn "download_fakenvapi function not available"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  PHASE 4: SCAN STEAM LIBRARIES
# ═══════════════════════════════════════════════════════════════════════════

scan_steam_libraries() {
    log_section "Scanning Steam libraries (multi-disk)"
    discover_steam_libraries
    if [[ ${#STEAM_LIBRARIES[@]} -eq 0 ]]; then
        log_error "No Steam libraries found!"
        return 1
    fi
    log_success "Detected ${#STEAM_LIBRARIES[@]} Steam library location(s):"
    for lib in "${STEAM_LIBRARIES[@]}"; do
        log_info "  ├─ $lib"
    done
}

# =============================================================================
#  PHASE 5: GAME DETECTION
# =============================================================================

scan_games() {
    log_section "Detecting installed games (multi-method)"
    detect_all_games
    GAMES_FOUND_COUNT=${#DETECTED_GAMES[@]}
    print_detected_games_table
    log_success "Detection finished: $GAMES_FOUND_COUNT compatible game(s)"
}

# ═══════════════════════════════════════════════════════════════════════════
#  PHASE 6: INSTALL
# ═══════════════════════════════════════════════════════════════════════════

install_optiscaler() {
    log_section "Installing OptiScaler to Found Games"
    
    [[ $GAMES_FOUND_COUNT -eq 0 ]] && { log_warn "No games found"; return 0; }
    
    local games_installed=0

    for rec in "${DETECTED_GAMES[@]}"; do
        local app_id game_path game_name
        IFS=';' read -r -a kvs <<< "$rec"
        for kv in "${kvs[@]}"; do
            local key="${kv%%=*}"
            local val="${kv#*=}"
            case "$key" in
                app_id) app_id="$val" ;;
                install_path) game_path="$val" ;;
                game_name) game_name="$val" ;;
            esac
        done

        log_subsection "Installing to: $game_name"

        if declare -f install_to_game >/dev/null; then
            if install_to_game "$game_path" "$app_id"; then
                ((games_installed++))
            fi
        else
            log_warn "install_to_game function not available (skipping real install)"
        fi
    done

    
    log_success "Installation complete: $games_installed/$GAMES_FOUND_COUNT game(s) updated"
}

# ═══════════════════════════════════════════════════════════════════════════
#  FINAL REPORT
# ═══════════════════════════════════════════════════════════════════════════

final_report() {
    log_section "Installation Summary"
    
    log_info "GPU Detected: $GPU_VENDOR"
    log_info "Steam Libraries: ${#STEAM_LIBRARIES[@]} found"
    log_info "Games Updated: $GAMES_FOUND_COUNT"
    log_info ""
    log_info "Next Steps:"
    log_info "  1. Launch your game from Steam"
    log_info "  2. Enable DLSS/FSR in graphics settings"
    log_info "  3. OptiScaler will automatically intercept and use FSR4"
    log_section "Installation Complete!"
}

error_handler() {
    log_error "Script failed at line $1"
    exit 1
}

trap 'error_handler $LINENO' ERR

# =============================================================================
#  MAIN
# =============================================================================

main() {
    load_modules
    parse_args "$@"
    # Update logging level after argument parsing
    if [[ -n "${LOG_LEVELS[$LOG_LEVEL]:-}" ]]; then
        CURRENT_LOG_LEVEL=${LOG_LEVELS[$LOG_LEVEL]}
    fi

    print_banner
    log_info "Starting OptiScaler Universal installation..."
    
    load_core_modules
    check_requirements
    detect_gpu
    download_deps
    
    if ! scan_steam_libraries; then
        log_error_exit "Failed to scan Steam libraries"
    fi
    
    scan_games
    
    $LIST_GAMES && { list_supported_games; exit 0; }
    $SCAN_ONLY && { log_info "Scan-only mode requested; exiting."; exit 0; }
    
    install_optiscaler
    final_report
}

main "$@"
