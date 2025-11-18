#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - DEPENDENCY DOWNLOADER
# ═══════════════════════════════════════════════════════════════════════════

OPTISCALER_VERSION="0.8.1"
FAKENVAPI_VERSION="0.8"
CACHE_DIR="$HOME/.optiscaler-universal/cache"

download_optiscaler() {
    log_info "Downloading OptiScaler $OPTISCALER_VERSION..."
    
    mkdir -p "$CACHE_DIR"
    
    local url="https://github.com/cdozdil/OptiScaler/releases/download/v${OPTISCALER_VERSION}/OptiScaler.zip"
    local dest="$CACHE_DIR/optiscaler-${OPTISCALER_VERSION}.zip"
    
    if [ -f "$dest" ]; then
        log_success "OptiScaler already cached"
    else
        if wget -q --show-progress -O "$dest" "$url"; then
            log_success "Downloaded OptiScaler"
        else
            log_error "Failed to download OptiScaler"
            return 1
        fi
    fi
    
    # Extract
    unzip -q -o "$dest" -d "$CACHE_DIR/optiscaler"
    log_success "OptiScaler extracted to cache"
}

download_fakenvapi() {
    log_info "Downloading fakenvapi $FAKENVAPI_VERSION..."
    
    local url="https://github.com/jp7677/dxvk-nvapi/releases/download/v${FAKENVAPI_VERSION}/dxvk-nvapi-v${FAKENVAPI_VERSION}.tar.gz"
    local dest="$CACHE_DIR/fakenvapi-${FAKENVAPI_VERSION}.tar.gz"
    
    if [ -f "$dest" ]; then
        log_success "fakenvapi already cached"
    else
        if wget -q --show-progress -O "$dest" "$url"; then
            log_success "Downloaded fakenvapi"
        else
            log_error "Failed to download fakenvapi"
            return 1
        fi
    fi
    
    # Extract
    tar -xzf "$dest" -C "$CACHE_DIR/"
    log_success "fakenvapi extracted to cache"
}

install_to_game() {
    local game_dir="$1"
    local app_id="$2"
    
    log_info "Installing OptiScaler to: $game_dir"
    
    # Create backup
    local backup_dir="$HOME/.optiscaler-universal/backups/$app_id/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Copy existing DLLs to backup
    for dll in nvngx.dll libxess.dll nvapi64.dll; do
        if [ -f "$game_dir/$dll" ]; then
            cp "$game_dir/$dll" "$backup_dir/"
            log_info "Backed up: $dll"
        fi
    done
    
    # Install OptiScaler DLLs
    cp "$CACHE_DIR/optiscaler/nvngx.dll" "$game_dir/"
    cp "$CACHE_DIR/optiscaler/libxess.dll" "$game_dir/"
    log_success "Installed OptiScaler DLLs"
    
    # Install fakenvapi (AMD/Intel only)
    if [[ "$GPU_VENDOR" == "AMD" || "$GPU_VENDOR" == "Intel" ]]; then
        cp "$CACHE_DIR/x64/nvapi64.dll" "$game_dir/"
        log_success "Installed fakenvapi"
    fi
    
    # Copy configs
    local config_dir="$HOME/.optiscaler-universal/generated"
    cp "$config_dir/OptiScaler.ini" "$game_dir/"
    cp "$config_dir/fakenvapi.ini" "$game_dir/"
    log_success "Installed configuration files"
    
    log_success "Installation complete for $game_dir"
}

