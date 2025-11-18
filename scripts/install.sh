#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - MAIN INSTALLER (ROBUST VERSION)
# ═══════════════════════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="0.1.0-alpha"
LICENSE="MIT - Open Source"

# ═══════════════════════════════════════════════════════════════════════════
#  INLINE LOGGER (Fallback)
# ═══════════════════════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${CYAN}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}✓ [SUCCESS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}⚠ [WARN]${NC} $*"; }
log_error() { echo -e "${RED}✗ [ERROR]${NC} $*" >&2; }
log_error_exit() { echo -e "${RED}✗ [ERROR]${NC} $*" >&2; exit 1; }
log_section() { echo ""; echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════════════════${NC}"; echo -e "${MAGENTA}  $*${NC}"; echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════════════════${NC}"; echo ""; }
log_subsection() { echo -e "${BLUE}>>> $*${NC}"; }

# ═══════════════════════════════════════════════════════════════════════════
#  INLINE STEAM SCANNER (Fallback if steam_scan.sh missing)
# ═══════════════════════════════════════════════════════════════════════════

detect_steam_libraries() {
    log_info "Scanning for Steam installations..."
    
    local -a all_libs
    
    # Check standard paths
    for path in "$HOME/.steam/steam" "$HOME/.local/share/Steam"; do
        if [[ -d "$path/steamapps/common" ]]; then
            all_libs+=("$path/steamapps/common")
            log_info "  ✓ Found: $path/steamapps/common"
        fi
    done
    
    # Check /mnt and /media
    for base in /mnt /media "/run/media/$USER"; do
        [[ ! -d "$base" ]] && continue
        while IFS= read -r -d '' dir; do
            local lib="${dir%/steamapps*}/steamapps/common"
            if [[ -d "$lib" && ! " ${all_libs[@]} " =~ " ${lib} " ]]; then
                all_libs+=("$lib")
                log_info "  ✓ Found: $lib"
            fi
        done < <(find "$base" -maxdepth 3 -type d -name "steamapps" -print0 2>/dev/null)
    done
    
    # Remove duplicates and output
    printf "%s\n" "${all_libs[@]}" | sort -u
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

load_modules() {
    log_section "Loading Core Modules"
    
    local modules=("downloader" "steam_scan")
    
    for module in "${modules[@]}"; do
        local module_path="$SCRIPT_DIR/core/${module}.sh"
        if [[ -f "$module_path" ]]; then
            source "$module_path" 2>/dev/null || log_warn "Loaded $module with warnings"
            log_success "Loaded: $module"
        else
            log_warn "Module not found: $module (will use fallback functions)"
        fi
    done
}

# ═══════════════════════════════════════════════════════════════════════════
#  PHASE 1: SYSTEM REQUIREMENTS
# ═══════════════════════════════════════════════════════════════════════════

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
    log_section "Scanning for Steam Libraries (Universal Multi-Disk Detection)"
    
    # Use detect_steam_libraries if available
    if declare -f detect_steam_libraries >/dev/null; then
        steam_libraries=($(detect_steam_libraries))
    else
        log_warn "detect_steam_libraries not found, using inline version"
        steam_libraries=($(detect_steam_libraries))
    fi
    
    if [[ ${#steam_libraries[@]} -eq 0 ]]; then
        log_error "No Steam libraries found!"
        return 1
    fi
    
    log_success "Detected ${#steam_libraries[@]} Steam library location(s):"
    for lib in "${steam_libraries[@]}"; do
        log_info "  ├─ $lib"
    done
}

# ═══════════════════════════════════════════════════════════════════════════
#  PHASE 5: SCAN FOR GAMES
# ═══════════════════════════════════════════════════════════════════════════

scan_games() {
    log_section "Scanning for Supported Games Across All Libraries"
    
    local profiles_dir="$SCRIPT_DIR/profiles/games"
    
    if [[ ! -d "$profiles_dir" ]]; then
        log_error "Games profiles directory not found: $profiles_dir"
        return 1
    fi
    
    local profile_count=$(ls -1 "$profiles_dir"/*.yaml 2>/dev/null | wc -l)
    log_info "Found $profile_count game profiles"
    
    declare -gA found_games
    local found=0
    
    for game_profile in "$profiles_dir"/*.yaml; do
        [[ ! -f "$game_profile" ]] && continue
        
        local game_name=$(basename "$game_profile" .yaml)
        local steam_dir=$(grep -m1 'steam_dir:' "$game_profile" 2>/dev/null | awk '{print $2}' | tr -d '"')
        local app_id=$(grep -m1 'app_id:' "$game_profile" 2>/dev/null | awk '{print $2}' | tr -d '"')
        
        [[ -z "$steam_dir" || -z "$app_id" ]] && continue
        
        log_info "Looking for: $game_name (APP: $app_id)"
        
        for lib in "${steam_libraries[@]}"; do
            local game_path="$lib/$steam_dir"
            if [[ -d "$game_path" ]]; then
                log_success "  ✓ Found at: $game_path"
                found_games["$app_id"]="$game_path"
                ((found++))
                break
            fi
        done
    done
    
    GAMES_FOUND_COUNT=$found
    log_success "Game scan complete: $found game(s) found"
}

# ═══════════════════════════════════════════════════════════════════════════
#  PHASE 6: INSTALL
# ═══════════════════════════════════════════════════════════════════════════

install_optiscaler() {
    log_section "Installing OptiScaler to Found Games"
    
    [[ $GAMES_FOUND_COUNT -eq 0 ]] && { log_warn "No games found"; return 0; }
    
    local games_installed=0
    
    for app_id in "${!found_games[@]}"; do
        local game_path="${found_games[$app_id]}"
        local game_name=$(basename "$game_path")
        
        log_subsection "Installing to: $game_name"
        
        if declare -f install_to_game >/dev/null; then
            if install_to_game "$game_path" "$app_id"; then
                ((games_installed++))
            fi
        else
            log_warn "install_to_game function not available"
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
    log_info "Steam Libraries: ${#steam_libraries[@]} found"
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

# ═══════════════════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════════════════

main() {
    print_banner
    echo "[INFO] Starting OptiScaler Universal installation..."
    echo ""
    
    load_modules
    check_requirements
    detect_gpu
    download_deps
    
    if ! scan_steam_libraries; then
        log_error_exit "Failed to scan Steam libraries"
    fi
    
    scan_games
    install_optiscaler
    final_report
}

main "$@"

