#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - DEPENDENCY DOWNLOADER (FINAL FIXED VERSION)
# ═══════════════════════════════════════════════════════════════════════════
#
#  Downloads OptiScaler (.7z) and fakenvapi (.tar.gz)
#  Installs CORRECT files to game directories
#
# ═══════════════════════════════════════════════════════════════════════════

CACHE_DIR="$HOME/.optiscaler-universal/cache"
OPTISCALER_LOCAL_DIR="${OPTISCALER_LOCAL_DIR:-/home/il1v3y/Downloads/Modeo2/Optiscaler_0.9.0-pre5 (20251031)}"
FSR4_MOD_DIR="${FSR4_MOD_DIR:-/home/il1v3y/Downloads/Modeo2/DLL Mods/FSR4 DLL (con escalador modificado)}"
INTEL_SDK_DIR="${INTEL_SDK_DIR:-/home/il1v3y/Downloads/Modeo2/DLL Mods/Intel SDK2.1}"
DRIVER_DLL_DIR="${DRIVER_DLL_DIR:-/home/il1v3y/Downloads/Modeo2/DLL Mods/DLL de drivers 23.9.1}"

# Use local extracted OptiScaler if available
use_local_optiscaler() {
    local src="$OPTISCALER_LOCAL_DIR"
    if [[ -d "$src" && -f "$src/OptiScaler.dll" ]]; then
        log_info "Using local OptiScaler from: $src"
        rm -rf "$CACHE_DIR/optiscaler"
        mkdir -p "$CACHE_DIR"
        cp -r "$src" "$CACHE_DIR/optiscaler"
        # If local config exists, stage it for installs
        if [[ -f "$src/OptiScaler.ini" ]]; then
            mkdir -p "$HOME/.optiscaler-universal/generated"
            cp "$src/OptiScaler.ini" "$HOME/.optiscaler-universal/generated/OptiScaler.ini"
            log_info "Staged OptiScaler.ini from local package"
        fi
        return 0
    fi
    return 1
}

# Overlay helper
apply_overlay() {
    local label="$1"
    local src="$2"
    local dest="$CACHE_DIR/optiscaler"
    [[ ! -d "$src" ]] && return 0
    [[ ! -d "$dest" ]] && return 0

    shopt -s nullglob
    local files=("$src"/*.dll "$src"/*.DLL)
    shopt -u nullglob
    [[ ${#files[@]} -eq 0 ]] && return 0

    log_info "Applying $label from: $src"
    for f in "${files[@]}"; do
        cp -f "$f" "$dest/"
        log_info "  ↳ Overrode $(basename "$f")"
    done
}

apply_overlays() {
    apply_overlay "modded FSR4 DLLs" "$FSR4_MOD_DIR"
    apply_overlay "Intel SDK2.1 DLLs" "$INTEL_SDK_DIR"
    apply_overlay "Driver DLL 23.9.1" "$DRIVER_DLL_DIR"
}

# Simple YAML boolean reader (best-effort)
yaml_bool() {
    local file="$1" key="$2" default_val="${3:-false}"
    [[ ! -f "$file" ]] && { echo "$default_val"; return; }
    local raw
    raw=$(grep -m1 -E "^[[:space:]]*${key}:" "$file" | head -1 | awk -F: '{gsub(/^[ \t]+|[ \t]+$/,"",$2);print tolower($2)}')
    case "$raw" in
        true|yes|y|on|1) echo "true" ;;
        false|no|n|off|0) echo "false" ;;
        *) echo "$default_val" ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════
#  CHECK OFFLINE - OptiScaler
# ═══════════════════════════════════════════════════════════════════════════

check_offline_optiscaler() {
    log_info "Checking for pre-downloaded OptiScaler..."
    
    # Check if already extracted in cache
    if [ -d "$CACHE_DIR/optiscaler" ] && [ -f "$CACHE_DIR/optiscaler/OptiScaler.dll" ]; then
        log_success "OptiScaler found in cache (offline)"
        return 0
    fi
    
    # Check for .7z files (current format)
    for location in "./OptiScaler_0.7.9.7z" "$HOME/OptiScaler_0.7.9.7z" "$HOME/Downloads/OptiScaler_0.7.9.7z" "./OptiScaler.7z" "$HOME/OptiScaler.7z" "$HOME/Downloads/OptiScaler.7z"; do
        if [ -f "$location" ]; then
            log_info "Found OptiScaler archive at: $location"
            mkdir -p "$CACHE_DIR/optiscaler"
            
            if ! command -v 7z &> /dev/null; then
                log_error "7z not found, attempting to install p7zip..."
                if ! sudo pacman -S p7zip --noconfirm 2>/dev/null; then
                    log_error "Failed to install p7zip"
                    return 1
                fi
            fi
            
            log_info "Extracting OptiScaler from $location..."
            if 7z x -o"$CACHE_DIR/optiscaler" "$location" > /dev/null 2>&1; then
                log_success "Extracted OptiScaler successfully"
                return 0
            else
                log_error "Failed to extract OptiScaler archive"
                return 1
            fi
        fi
    done
    
    # Check for .zip files (legacy support)
    for location in "./OptiScaler.zip" "$HOME/OptiScaler.zip" "$HOME/Downloads/OptiScaler.zip"; do
        if [ -f "$location" ]; then
            log_info "Found OptiScaler.zip at: $location"
            mkdir -p "$CACHE_DIR/optiscaler"
            
            log_info "Extracting OptiScaler from $location..."
            if unzip -o -q "$location" -d "$CACHE_DIR/optiscaler"; then
                log_success "Extracted OptiScaler successfully"
                return 0
            else
                log_error "Failed to extract OptiScaler zip"
                return 1
            fi
        fi
    done
    
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════
#  DOWNLOAD OptiScaler from GitHub
# ═══════════════════════════════════════════════════════════════════════════

download_optiscaler() {
    log_info "Downloading OptiScaler from GitHub..."
    
    mkdir -p "$CACHE_DIR"
    
    # Prefer locally provided extracted package
    if use_local_optiscaler; then
        log_success "OptiScaler loaded from local directory"
        apply_overlays
        return 0
    fi

    # First check offline
    if check_offline_optiscaler; then
        apply_overlays
        return 0
    fi
    
    log_info "No cached/offline OptiScaler found, attempting online download..."
    
    # Query GitHub API for latest release
    log_info "Querying GitHub API for latest release..."
    local api_response
    api_response=$(curl -s "https://api.github.com/repos/optiscaler/OptiScaler/releases/latest")
    
    # Find the .7z file (the compiled binary)
    local download_url
    download_url=$(echo "$api_response" | grep -o '"browser_download_url": "[^"]*\.7z"' | head -1 | sed 's/.*": "\([^"]*\)".*/\1/')
    
    if [[ -z "$download_url" ]]; then
        log_error "Could not find .7z file in latest OptiScaler release"
        log_info "Available files in latest release:"
        echo "$api_response" | grep -o '"name": "[^"]*"' | sed 's/.*": "\([^"]*\)".*/  - \1/'
        
        log_error ""
        log_error "OFFLINE SOLUTION:"
        log_error "1. Visit: https://github.com/optiscaler/OptiScaler/releases"
        log_error "2. Download the .7z file (OptiScaler_*.7z)"
        log_error "3. Place it in one of these directories:"
        log_error "   - Current directory (.)"
        log_error "   - Home directory ($HOME)"
        log_error "   - Downloads folder ($HOME/Downloads)"
        log_error "4. Run this script again"
        log_error ""
        return 1
    fi
    
    local dest="$CACHE_DIR/optiscaler-latest.7z"
    
    log_info "Downloading from: $download_url"
    
    if wget --timeout=30 --tries=3 --show-progress -O "$dest" "$download_url" 2>&1; then
        log_success "Downloaded OptiScaler"
        mkdir -p "$CACHE_DIR/optiscaler"
        
        # Extract 7z file
        log_info "Extracting OptiScaler (7z format)..."
        
        if ! command -v 7z &> /dev/null; then
            log_info "Installing p7zip..."
            if ! sudo pacman -S p7zip --noconfirm; then
                log_error "Failed to install p7zip"
                return 1
            fi
        fi
        
        if 7z x -o"$CACHE_DIR/optiscaler" "$dest" > /dev/null 2>&1; then
            log_success "Extracted OptiScaler successfully"
            
            # Verify DLL exists
            if [ -f "$CACHE_DIR/optiscaler/OptiScaler.dll" ]; then
                log_success "Verified OptiScaler.dll present"
                apply_overlays
                return 0
            else
                log_error "OptiScaler.dll missing after extraction"
                log_info "Archive contents:"
                ls -la "$CACHE_DIR/optiscaler/" 2>/dev/null || echo "  (extraction may have failed)"
                return 1
            fi
        else
            log_error "Failed to extract OptiScaler archive"
            return 1
        fi
    else
        log_error "Failed to download OptiScaler"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  CHECK OFFLINE - fakenvapi
# ═══════════════════════════════════════════════════════════════════════════

check_offline_fakenvapi() {
    log_info "Checking for pre-downloaded fakenvapi..."
    
    if [ -d "$CACHE_DIR/x64" ] && [ -f "$CACHE_DIR/x64/nvapi64.dll" ]; then
        log_success "fakenvapi found in cache (offline)"
        return 0
    fi
    
    for location in "./dxvk-nvapi.tar.gz" "$HOME/dxvk-nvapi.tar.gz" "$HOME/Downloads/dxvk-nvapi.tar.gz" "./fakenvapi.tar.gz" "$HOME/fakenvapi.tar.gz" "$HOME/Downloads/fakenvapi.tar.gz"; do
        if [ -f "$location" ]; then
            log_info "Found fakenvapi archive at: $location"
            
            log_info "Extracting fakenvapi..."
            if tar -xzf "$location" -C "$CACHE_DIR"; then
                log_success "Extracted fakenvapi successfully"
                return 0
            else
                log_error "Failed to extract fakenvapi archive"
                return 1
            fi
        fi
    done
    
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════
#  DOWNLOAD fakenvapi from GitHub
# ═══════════════════════════════════════════════════════════════════════════

download_fakenvapi() {
    log_info "Downloading fakenvapi from GitHub..."
    
    mkdir -p "$CACHE_DIR"
    
    # First check offline
    if check_offline_fakenvapi; then
        return 0
    fi
    
    log_info "No cached/offline fakenvapi found, attempting online download..."
    
    # Query GitHub API for latest release
    log_info "Querying GitHub API for latest release..."
    local api_response
    api_response=$(curl -s "https://api.github.com/repos/jp7677/dxvk-nvapi/releases/latest")
    
    # Find the .tar.gz file
    local download_url
    download_url=$(echo "$api_response" | grep -o '"browser_download_url": "[^"]*\.tar\.gz"' | head -1 | sed 's/.*": "\([^"]*\)".*/\1/')
    
    if [[ -z "$download_url" ]]; then
        log_error "Could not find .tar.gz file in latest fakenvapi release"
        log_info "Available files in latest release:"
        echo "$api_response" | grep -o '"name": "[^"]*"' | sed 's/.*": "\([^"]*\)".*/  - \1/'
        
        log_error ""
        log_error "OFFLINE SOLUTION:"
        log_error "1. Visit: https://github.com/jp7677/dxvk-nvapi/releases"
        log_error "2. Download the .tar.gz file"
        log_error "3. Place it in one of these directories:"
        log_error "   - Current directory (.)"
        log_error "   - Home directory ($HOME)"
        log_error "   - Downloads folder ($HOME/Downloads)"
        log_error "4. Run this script again"
        log_error ""
        return 1
    fi
    
    local dest="$CACHE_DIR/fakenvapi-latest.tar.gz"
    
    log_info "Downloading from: $download_url"
    
    if wget --timeout=30 --tries=3 --show-progress -O "$dest" "$download_url" 2>&1; then
        log_success "Downloaded fakenvapi"
        
        log_info "Extracting fakenvapi..."
        if tar -xzf "$dest" -C "$CACHE_DIR"; then
            log_success "Extracted fakenvapi successfully"
            
            # Verify DLL
            if [ -f "$CACHE_DIR/x64/nvapi64.dll" ]; then
                log_success "Verified nvapi64.dll present"
                return 0
            else
                log_warn "nvapi64.dll not found at expected location"
                log_info "Archive contents:"
                ls -la "$CACHE_DIR/" 2>/dev/null | grep -E "^d|nvapi"
                return 0
            fi
        else
            log_error "Failed to extract fakenvapi archive"
            return 1
        fi
    else
        log_error "Failed to download fakenvapi"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  INSTALL TO GAME - CORRECTED VERSION
# ═══════════════════════════════════════════════════════════════════════════

install_to_game() {
    local game_dir="$1"
    local app_id="$2"
    local profile_path="${3:-}"
    
    log_info "Installing OptiScaler to game directory: $game_dir"
    
    if [ ! -d "$game_dir" ]; then
        log_error "Game directory does not exist: $game_dir"
        return 1
    fi

    # Component selection defaults
    local install_optiscaler=true
    local install_xess=true
    local install_fakenvapi=false
    [[ "$GPU_VENDOR" =~ (AMD|Intel) ]] && install_fakenvapi=true

    if [[ -n "$profile_path" && -f "$profile_path" ]]; then
        install_optiscaler=$(yaml_bool "$profile_path" "install_optiscaler" "$install_optiscaler")
        install_xess=$(yaml_bool "$profile_path" "install_xess" "$install_xess")
        install_fakenvapi=$(yaml_bool "$profile_path" "install_fakenvapi" "$install_fakenvapi")
    fi
    
    # Create backup
    local backup_dir="$HOME/.optiscaler-universal/backups/$app_id/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup existing files
    local files_to_backup=(
        "OptiScaler.dll"
        "libxess.dll"
        "libxess_dx11.dll"
        "nvapi64.dll"
        "OptiScaler.ini"
        "fakenvapi.ini"
        "amd_fidelityfx_dx12.dll"
        "amd_fidelityfx_framegeneration_dx12.dll"
        "amd_fidelityfx_upscaler_dx12.dll"
        "amd_fidelityfx_vk.dll"
    )
    
    for file in "${files_to_backup[@]}"; do
        if [ -f "$game_dir/$file" ]; then
            cp "$game_dir/$file" "$backup_dir/"
            log_info "  ↳ Backed up: $file"
        fi
    done
    
    # ═══════════════════════════════════════════════════════════════════════
    # Install OptiScaler Core Files
    # ═══════════════════════════════════════════════════════════════════════
    
    local installation_success=true
    
    # OptiScaler.dll (MAIN FILE - REQUIRED)
    if [[ "$install_optiscaler" == "true" ]]; then
        if [ -f "$CACHE_DIR/optiscaler/OptiScaler.dll" ]; then
            cp "$CACHE_DIR/optiscaler/OptiScaler.dll" "$game_dir/"
            log_success "  ↳ Installed: OptiScaler.dll (main plugin)"
        else
            log_error "  ✗ CRITICAL: OptiScaler.dll missing"
            installation_success=false
        fi
    else
        log_info "  ℹ Skipped OptiScaler.dll (profile preference)"
    fi
    
    # libxess.dll (XeSS support)
    if [[ "$install_xess" == "true" ]]; then
        if [ -f "$CACHE_DIR/optiscaler/libxess.dll" ]; then
            cp "$CACHE_DIR/optiscaler/libxess.dll" "$game_dir/"
            log_success "  ↳ Installed: libxess.dll"
        else
            log_warn "  ⚠ Optional: libxess.dll missing"
        fi
        
        if [ -f "$CACHE_DIR/optiscaler/libxess_dx11.dll" ]; then
            cp "$CACHE_DIR/optiscaler/libxess_dx11.dll" "$game_dir/"
            log_success "  ↳ Installed: libxess_dx11.dll"
        fi
    else
        log_info "  ℹ Skipped XeSS runtime (profile preference)"
    fi
    
    # ═══════════════════════════════════════════════════════════════════════
    # Install AMD FidelityFX Libraries (FSR4 support)
    # ═══════════════════════════════════════════════════════════════════════
    
    local fsr_files=(
        "amd_fidelityfx_dx12.dll"
        "amd_fidelityfx_framegeneration_dx12.dll"
        "amd_fidelityfx_upscaler_dx12.dll"
        "amd_fidelityfx_vk.dll"
    )
    
    for fsr_dll in "${fsr_files[@]}"; do
        if [ -f "$CACHE_DIR/optiscaler/$fsr_dll" ]; then
            cp "$CACHE_DIR/optiscaler/$fsr_dll" "$game_dir/"
            log_success "  ↳ Installed: $fsr_dll"
        else
            log_warn "  ⚠ Optional: $fsr_dll missing"
        fi
    done
    
    # ═══════════════════════════════════════════════════════════════════════
    # Install fakenvapi (GPU Spoofing for AMD/Intel)
    # ═══════════════════════════════════════════════════════════════════════
    
    if [[ "$install_fakenvapi" == "true" ]]; then
        if [ -f "$CACHE_DIR/x64/nvapi64.dll" ]; then
            cp "$CACHE_DIR/x64/nvapi64.dll" "$game_dir/"
            log_success "  ↳ Installed: fakenvapi (nvapi64.dll - GPU spoofing)"
        else
            log_warn "  ⚠ fakenvapi nvapi64.dll not found"
        fi
    else
        log_info "  ℹ Skipping fakenvapi (profile preference or NVIDIA GPU)"
    fi
    
    # ═══════════════════════════════════════════════════════════════════════
    # Install Configuration Files
    # ═══════════════════════════════════════════════════════════════════════
    
    local config_dir="$HOME/.optiscaler-universal/generated"
    
    if [[ "$install_optiscaler" == "true" ]]; then
        if [ -f "$config_dir/OptiScaler.ini" ]; then
            cp "$config_dir/OptiScaler.ini" "$game_dir/"
            log_success "  ↳ Installed: OptiScaler.ini (configuration)"
        else
            log_warn "  ⚠ OptiScaler.ini not found"
        fi
    fi
    
    if [[ "$install_fakenvapi" == "true" ]]; then
        if [ -f "$config_dir/fakenvapi.ini" ]; then
            cp "$config_dir/fakenvapi.ini" "$game_dir/"
            log_success "  ↳ Installed: fakenvapi.ini (Anti-Lag 2 config)"
        fi
    fi
    
    # ═══════════════════════════════════════════════════════════════════════
    # Final Status
    # ═══════════════════════════════════════════════════════════════════════
    
    if [ "$installation_success" = true ]; then
        log_success "Installation complete for game: $app_id"
        return 0
    else
        log_error "Installation failed - critical files missing"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  EXPORT FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

export -f check_offline_optiscaler
export -f check_offline_fakenvapi
export -f download_optiscaler
export -f download_fakenvapi
export -f install_to_game
