#!/bin/bash

# =============================================================================
#  OPTISCALER UNIVERSAL - MAIN INSTALLER (ROBUST VERSION)
# =============================================================================

set -eo pipefail

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
AUTO_PROFILE_UNKNOWN=${AUTO_PROFILE_UNKNOWN:-false}
SKIP_PROFILE_UNKNOWN=${SKIP_PROFILE_UNKNOWN:-false}

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
    DELIM=${DELIM:-$'\x1f'}
}

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]
  --verbose           Verbose logging (DEBUG)
  --debug             Max logging (TRACE) with disk/mount details
  --list-games        List supported games (profiles) and exit
  --scan-only         Scan Steam libraries without installing
  --force-rescan      Ignore cache and rescan libraries
  --auto-profile-unknown   Auto-generate generic profiles for games without profile
  --skip-profile-unknown   Do not offer generic profiles for games without profile
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
            --auto-profile-unknown) AUTO_PROFILE_UNKNOWN=true ;;
            --skip-profile-unknown) SKIP_PROFILE_UNKNOWN=true ;;
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

maybe_generate_generic_profiles() {
    local unsupported_count=${#DETECTED_UNSUPPORTED[@]}
    (( unsupported_count == 0 )) && return

    # Helper to prompt booleans with default
    _prompt_bool() {
        local question="$1" default="${2:-y}" answer
        local prompt="[$([[ "$default" =~ ^[Yy]$ ]] && echo Y || echo y)/$([[ "$default" =~ ^[Yy]$ ]] && echo n || echo N)]"
        echo -n "$question $prompt "
        read -r answer
        [[ -z "$answer" ]] && answer="$default"
        [[ "$answer" =~ ^[Yy]$ ]] && return 0 || return 1
    }

    # Filter unsupported entries that have an AppID; skip runtimes without manifest
    local -a creatable=()
    local rec app_id
    for rec in "${DETECTED_UNSUPPORTED[@]}"; do
        app_id="$(echo "$rec" | tr "$DELIM" '\n' | awk -F= '$1=="app_id"{print $2}' | head -1)"
        [[ -n "$app_id" ]] && creatable+=("$rec")
    done

    (( ${#creatable[@]} == 0 )) && { log_info "Unsupported items lack AppID; no generic profiles created."; return; }

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

        local base="$(basename "$install_path")"
        local game_id="$(echo "$base" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-*//;s/-*$//')"
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
        [[ "$GPU_VENDOR" =~ (AMD|Intel) ]] && install_fakenvapi=true
        local preset="balanced"
        local dlss_to_fsr=true

        if ! $AUTO_PROFILE_UNKNOWN && ! $SKIP_PROFILE_UNKNOWN; then
            _prompt_bool "Install OptiScaler DLL replacement?" "y" && install_optiscaler=true || install_optiscaler=false
            _prompt_bool "Install XeSS runtime (libxess.dll)?" "y" && install_xess=true || install_xess=false
            local fakedef="n"; [[ "$GPU_VENDOR" =~ (AMD|Intel) ]] && fakedef="y"
            _prompt_bool "Install fakenvapi (NVAPI shim)?" "$fakedef" && install_fakenvapi=true || install_fakenvapi=false
            echo -n "Choose OptiScaler preset [quality/balanced/performance/ultra-performance] (default: balanced): "
            read -r preset
            [[ -z "$preset" ]] && preset="balanced"
            _prompt_bool "Enable DLSS->FSR translation (dlss_to_fsr)?" "y" && dlss_to_fsr=true || dlss_to_fsr=false
        fi

        cat > "$profile_file" <<EOF
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

install_optiscaler() {
    log_section "Installing OptiScaler to Found Games"
    
    # Avoid aborting on non-critical copy errors during per-game install
    set +e
    if [[ $GAMES_FOUND_COUNT -eq 0 ]]; then
        log_warn "No games found"
        set -e
        return 0
    fi
    
    local games_installed=0

    for rec in "${DETECTED_GAMES[@]}"; do
        local app_id game_path game_name profile_path
        IFS="$DELIM" read -r -a kvs <<< "$rec"
        for kv in "${kvs[@]}"; do
            local key="${kv%%=*}"
            local val="${kv#*=}"
            case "$key" in
                app_id) app_id="$val" ;;
                install_path) game_path="$val" ;;
                game_name) game_name="$val" ;;
                profile_matched) profile_path="$val" ;;
            esac
        done

        log_info "Installing to: $game_name"

        if declare -f install_to_game >/dev/null; then
            if install_to_game "$game_path" "$app_id" "$profile_path"; then
                ((games_installed++))
            fi
        else
            log_warn "install_to_game function not available (skipping real install)"
        fi
    done

    
    log_success "Installation complete: $games_installed/$GAMES_FOUND_COUNT game(s) updated"
    set -e
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
    else
        CURRENT_LOG_LEVEL=${LOG_LEVELS[INFO]}
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
    maybe_generate_generic_profiles
    
    $LIST_GAMES && { list_supported_games; exit 0; }
    $SCAN_ONLY && { log_info "Scan-only mode requested; exiting."; exit 0; }
    
    install_optiscaler
    final_report
}

main "$@"
