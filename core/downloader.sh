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
    
    # First check offline
    if check_offline_optiscaler; then
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
    
    log_info "Installing OptiScaler to game directory: $game_dir"
    
    if [ ! -d "$game_dir" ]; then
        log_error "Game directory does not exist: $game_dir"
        return 1
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
    if [ -f "$CACHE_DIR/optiscaler/OptiScaler.dll" ]; then
        cp "$CACHE_DIR/optiscaler/OptiScaler.dll" "$game_dir/"
        log_success "  ↳ Installed: OptiScaler.dll (main plugin)"
    else
        log_error "  ✗ CRITICAL: OptiScaler.dll missing"
        installation_success=false
    fi
    
    # libxess.dll (XeSS support)
    if [ -f "$CACHE_DIR/optiscaler/libxess.dll" ]; then
        cp "$CACHE_DIR/optiscaler/libxess.dll" "$game_dir/"
        log_success "  ↳ Installed: libxess.dll"
    else
        log_warn "  ⚠ Optional: libxess.dll missing"
    fi
    
    # libxess_dx11.dll (XeSS for DirectX 11)
    if [ -f "$CACHE_DIR/optiscaler/libxess_dx11.dll" ]; then
        cp "$CACHE_DIR/optiscaler/libxess_dx11.dll" "$game_dir/"
        log_success "  ↳ Installed: libxess_dx11.dll"
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
    
    if [[ "$GPU_VENDOR" == "AMD" || "$GPU_VENDOR" == "Intel" ]]; then
        if [ -f "$CACHE_DIR/x64/nvapi64.dll" ]; then
            cp "$CACHE_DIR/x64/nvapi64.dll" "$game_dir/"
            log_success "  ↳ Installed: fakenvapi (nvapi64.dll - GPU spoofing)"
        else
            log_warn "  ⚠ fakenvapi nvapi64.dll not found"
        fi
    else
        log_info "  ℹ Skipping fakenvapi (NVIDIA GPU detected)"
    fi
    
    # ═══════════════════════════════════════════════════════════════════════
    # Install Configuration Files
    # ═══════════════════════════════════════════════════════════════════════
    
    local config_dir="$HOME/.optiscaler-universal/generated"
    
    if [ -f "$config_dir/OptiScaler.ini" ]; then
        cp "$config_dir/OptiScaler.ini" "$game_dir/"
        log_success "  ↳ Installed: OptiScaler.ini (configuration)"
    else
        log_warn "  ⚠ OptiScaler.ini not found"
    fi
    
    if [[ "$GPU_VENDOR" == "AMD" || "$GPU_VENDOR" == "Intel" ]]; then
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

