#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - DEPENDENCY DOWNLOADER
# ═══════════════════════════════════════════════════════════════════════════

OPTISCALER_VERSION="0.8.1"
FAKENVAPI_VERSION="0.8"
CACHE_DIR="$HOME/.optiscaler-universal/cache"
OPTISCALER_LOCAL_DIR="${OPTISCALER_LOCAL_DIR:-/home/il1v3y/Downloads/Modeo2/Optiscaler_0.9.0-pre5 (20251031)}"
FSR4_MOD_DIR="${FSR4_MOD_DIR:-/home/il1v3y/Downloads/Modeo2/DLL Mods/FSR4 DLL (con escalador modificado)}"
INTEL_SDK_DIR="${INTEL_SDK_DIR:-/home/il1v3y/Downloads/Modeo2/DLL Mods/Intel SDK2.1}"
DRIVER_DLL_DIR="${DRIVER_DLL_DIR:-/home/il1v3y/Downloads/Modeo2/DLL Mods/DLL de drivers 23.9.1}"

# ──────────────────────────────────────────────────────────────────────────
#  Helpers
# ──────────────────────────────────────────────────────────────────────────

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

use_local_optiscaler() {
    local src="$OPTISCALER_LOCAL_DIR"
    if [[ -d "$src" && -f "$src/OptiScaler.dll" ]]; then
        log_info "Using local OptiScaler from: $src"
        rm -rf "$CACHE_DIR/optiscaler"
        mkdir -p "$CACHE_DIR"
        cp -r "$src" "$CACHE_DIR/optiscaler"
        # Stage configs if present
        if [[ -f "$src/OptiScaler.ini" ]]; then
            mkdir -p "$HOME/.optiscaler-universal/generated"
            cp "$src/OptiScaler.ini" "$HOME/.optiscaler-universal/generated/OptiScaler.ini"
            log_info "Staged OptiScaler.ini from local package"
        fi
        return 0
    fi
    return 1
}

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

download_optiscaler() {
    log_info "Downloading OptiScaler $OPTISCALER_VERSION..."
    
    mkdir -p "$CACHE_DIR"
    
    if use_local_optiscaler; then
        log_success "OptiScaler loaded from local directory"
        apply_overlays
        return 0
    fi
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
    apply_overlays
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
    local profile_path="${3:-}"
    
    log_info "Installing OptiScaler to: $game_dir"
    
    # Create backup
    local backup_dir="$HOME/.optiscaler-universal/backups/$app_id/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    # Component selection (defaults)
    local install_optiscaler=true
    local install_xess=true
    local install_fakenvapi=false
    [[ "$GPU_VENDOR" =~ (AMD|Intel) ]] && install_fakenvapi=true

    if [[ -n "$profile_path" && -f "$profile_path" ]]; then
        install_optiscaler=$(yaml_bool "$profile_path" "install_optiscaler" "$install_optiscaler")
        install_xess=$(yaml_bool "$profile_path" "install_xess" "$install_xess")
        install_fakenvapi=$(yaml_bool "$profile_path" "install_fakenvapi" "$install_fakenvapi")
    fi

    # Copy existing DLLs to backup only if they will be overwritten
    for dll in nvngx.dll libxess.dll nvapi64.dll; do
        if [ -f "$game_dir/$dll" ]; then
            cp "$game_dir/$dll" "$backup_dir/"
            log_info "Backed up: $dll"
        fi
    done

    # Install OptiScaler DLLs
    if [[ "$install_optiscaler" == "true" ]]; then
        cp "$CACHE_DIR/optiscaler/nvngx.dll" "$game_dir/"
        log_success "Installed OptiScaler (nvngx.dll)"
    else
        log_info "Skipped OptiScaler nvngx.dll (profile preference)"
    fi

    # Install XeSS runtime (optional)
    if [[ "$install_xess" == "true" ]]; then
        if [[ -f "$CACHE_DIR/optiscaler/libxess.dll" ]]; then
            cp "$CACHE_DIR/optiscaler/libxess.dll" "$game_dir/"
            log_success "Installed XeSS runtime (libxess.dll)"
        else
            log_warn "XeSS runtime not found in cache; skipping libxess.dll"
        fi
    else
        log_info "Skipped XeSS runtime (profile preference)"
    fi

    # Install fakenvapi (NVAPI shim)
    if [[ "$install_fakenvapi" == "true" ]]; then
        if [[ -f "$CACHE_DIR/x64/nvapi64.dll" ]]; then
            cp "$CACHE_DIR/x64/nvapi64.dll" "$game_dir/"
            log_success "Installed fakenvapi (nvapi64.dll)"
        else
            log_warn "fakenvapi nvapi64.dll not found in cache; skipping"
        fi
    else
        log_info "Skipped fakenvapi (profile preference)"
    fi
    
    # Copy configs
    local config_dir="$HOME/.optiscaler-universal/generated"
    if [[ "$install_optiscaler" == "true" && -f "$config_dir/OptiScaler.ini" ]]; then
        cp "$config_dir/OptiScaler.ini" "$game_dir/"
        log_success "Installed OptiScaler.ini"
    elif [[ "$install_optiscaler" == "true" ]]; then
        log_warn "OptiScaler.ini not found; skipped config copy"
    fi

    if [[ "$install_fakenvapi" == "true" && -f "$config_dir/fakenvapi.ini" ]]; then
        cp "$config_dir/fakenvapi.ini" "$game_dir/"
        log_success "Installed fakenvapi.ini"
    elif [[ "$install_fakenvapi" == "true" ]]; then
        log_warn "fakenvapi.ini not found; skipped config copy"
    fi
    
    log_success "Installation complete for $game_dir"
}
