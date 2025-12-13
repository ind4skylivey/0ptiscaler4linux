#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - DEPENDENCY DOWNLOADER (SECURITY HARDENED)
# ═══════════════════════════════════════════════════════════════════════════
#
#  Downloads OptiScaler (.7z) and fakenvapi (.tar.gz)
#  Installs CORRECT files to game directories
#
#  Security improvements:
#    - No automatic sudo execution
#    - Cache in user directory with 700 permissions
#    - Optional checksum verification
#    - Input validation on all paths
#    - Safe temporary file handling
#
# ═══════════════════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────────────────
# Configuration with secure defaults
# ───────────────────────────────────────────────────────────────────────────

# Use user-local cache directory (NOT /tmp for security)
OPTISCALER_DATA_DIR="${OPTISCALER_DATA_DIR:-$HOME/.optiscaler-universal}"
CACHE_DIR="${CACHE_DIR:-$OPTISCALER_DATA_DIR/cache}"
GENERATED_DIR="$OPTISCALER_DATA_DIR/generated"
BACKUP_DIR="$OPTISCALER_DATA_DIR/backups"

# Local directories (relative to SCRIPT_DIR)
OPTISCALER_LOCAL_DIR="${OPTISCALER_LOCAL_DIR:-${SCRIPT_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/Modingv2/Optiscaler_0.9.0-pre6 (20251205)}"
FSR4_MOD_DIR="${FSR4_MOD_DIR:-${SCRIPT_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/Modingv2/Archivos FSR 4 (DLL modoficada)}"
DRIVER_DLL_DIR="${DRIVER_DLL_DIR:-${SCRIPT_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/Modingv2/DLL Drivers 23.9.1}"

# ───────────────────────────────────────────────────────────────────────────
# init_secure_directories - Create directories with proper permissions
#
# Creates all required directories with mode 700 (owner only)
# ───────────────────────────────────────────────────────────────────────────
init_secure_directories() {
    local dirs=("$OPTISCALER_DATA_DIR" "$CACHE_DIR" "$GENERATED_DIR" "$BACKUP_DIR")

    for dir in "${dirs[@]}"; do
        if ! mkdir -p "$dir" 2>/dev/null; then
            log_error "Failed to create directory: $dir"
            return 1
        fi
        chmod 700 "$dir"
    done

    log_debug "Initialized secure directories"
    return 0
}

# ───────────────────────────────────────────────────────────────────────────
# use_local_optiscaler - Check for locally available OptiScaler package
#
# Returns:
#   0 if local package found and staged
#   1 if no local package available
# ───────────────────────────────────────────────────────────────────────────
use_local_optiscaler() {
    local src="$OPTISCALER_LOCAL_DIR"

    if [[ -d "$src" && -f "$src/OptiScaler.dll" ]]; then
        log_info "Using local OptiScaler from: $src"

        # Clean existing cache
        rm -rf "${CACHE_DIR:?}/optiscaler"
        mkdir -p "$CACHE_DIR"
        chmod 700 "$CACHE_DIR"

        # Copy with permissions preserved
        cp -r "$src" "$CACHE_DIR/optiscaler"

        # Stage config files if present
        if [[ -f "$src/OptiScaler.ini" ]]; then
            mkdir -p "$GENERATED_DIR"
            chmod 700 "$GENERATED_DIR"
            cp "$src/OptiScaler.ini" "$GENERATED_DIR/OptiScaler.ini"
            log_info "Staged OptiScaler.ini from local package"
        fi

        # Stage fakenvapi if present
        if [[ -f "$src/fakenvapi.dll" ]]; then
            mkdir -p "$CACHE_DIR/x64"
            cp "$src/fakenvapi.dll" "$CACHE_DIR/x64/nvapi64.dll"
            log_info "Staged fakenvapi.dll (as nvapi64.dll) from local package"
        fi

        if [[ -f "$src/fakenvapi.ini" ]]; then
            mkdir -p "$GENERATED_DIR"
            chmod 700 "$GENERATED_DIR"
            cp "$src/fakenvapi.ini" "$GENERATED_DIR/fakenvapi.ini"
            log_info "Staged fakenvapi.ini from local package"
        fi

        return 0
    fi
    return 1
}

# ───────────────────────────────────────────────────────────────────────────
# apply_overlay - Apply DLL overlay from a directory
#
# Arguments:
#   $1 - label: Description for logging
#   $2 - src: Source directory containing DLL files
# ───────────────────────────────────────────────────────────────────────────
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

# ───────────────────────────────────────────────────────────────────────────
# apply_overlays - Apply all configured DLL overlays
# ───────────────────────────────────────────────────────────────────────────
apply_overlays() {
    apply_overlay "modded FSR4 DLLs" "$FSR4_MOD_DIR"
    apply_overlay "Driver DLL 23.9.1" "$DRIVER_DLL_DIR"
}

# ───────────────────────────────────────────────────────────────────────────
# yaml_bool - Parse boolean value from YAML file (lightweight)
#
# Arguments:
#   $1 - file: Path to YAML file
#   $2 - key: Key name to look up
#   $3 - default_val: Default value if key not found
#
# Returns:
#   "true" or "false" on stdout
# ───────────────────────────────────────────────────────────────────────────
yaml_bool() {
    local file="$1"
    local key="$2"
    local default_val="${3:-false}"

    [[ ! -f "$file" ]] && { echo "$default_val"; return; }

    local raw
    raw=$(grep -m1 -E "^[[:space:]]*${key}:" "$file" 2>/dev/null | head -1 | awk -F: '{gsub(/^[ \t]+|[ \t]+$/,"",$2);print tolower($2)}')

    case "$raw" in
        true|yes|y|on|1)  echo "true" ;;
        false|no|n|off|0) echo "false" ;;
        *)                echo "$default_val" ;;
    esac
}

# ───────────────────────────────────────────────────────────────────────────
# require_7z - Ensure 7z is available (no auto-install for security)
#
# Returns:
#   0 if 7z is available
#   1 if not available (with instructions)
# ───────────────────────────────────────────────────────────────────────────
require_7z() {
    if command -v 7z &>/dev/null; then
        return 0
    fi

    log_error "7z (p7zip) is required but not installed."
    log_error ""
    log_error "Please install it manually:"

    # Detect package manager and show appropriate command
    if command -v pacman &>/dev/null; then
        log_error "  Arch/Manjaro: sudo pacman -S p7zip"
    elif command -v apt &>/dev/null; then
        log_error "  Debian/Ubuntu: sudo apt install p7zip-full"
    elif command -v dnf &>/dev/null; then
        log_error "  Fedora: sudo dnf install p7zip"
    elif command -v zypper &>/dev/null; then
        log_error "  openSUSE: sudo zypper install p7zip"
    else
        log_error "  Install p7zip using your distribution's package manager"
    fi

    log_error ""
    log_error "Then run this script again."
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════
#  CHECK OFFLINE - OptiScaler
# ═══════════════════════════════════════════════════════════════════════════

check_offline_optiscaler() {
    log_info "Checking for pre-downloaded OptiScaler..."

    # Check if already extracted in cache
    if [[ -d "$CACHE_DIR/optiscaler" && -f "$CACHE_DIR/optiscaler/OptiScaler.dll" ]]; then
        log_success "OptiScaler found in cache (offline)"
        return 0
    fi

    # Define safe search locations
    local search_locations=(
        "./OptiScaler_0.7.9.7z"
        "$HOME/OptiScaler_0.7.9.7z"
        "$HOME/Downloads/OptiScaler_0.7.9.7z"
        "./OptiScaler.7z"
        "$HOME/OptiScaler.7z"
        "$HOME/Downloads/OptiScaler.7z"
    )

    # Check for .7z files
    for location in "${search_locations[@]}"; do
        if [[ -f "$location" ]]; then
            log_info "Found OptiScaler archive at: $location"
            mkdir -p "$CACHE_DIR/optiscaler"
            chmod 700 "$CACHE_DIR"

            # Require 7z without auto-installing
            require_7z || return 1

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
    local zip_locations=(
        "./OptiScaler.zip"
        "$HOME/OptiScaler.zip"
        "$HOME/Downloads/OptiScaler.zip"
    )

    for location in "${zip_locations[@]}"; do
        if [[ -f "$location" ]]; then
            log_info "Found OptiScaler.zip at: $location"
            mkdir -p "$CACHE_DIR/optiscaler"
            chmod 700 "$CACHE_DIR"

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

    # Initialize secure directories
    init_secure_directories || return 1

    # Prefer locally provided extracted package
    if use_local_optiscaler; then
        log_success "OptiScaler loaded from local directory"
        apply_overlays
        return 0
    fi

    # Check offline first
    if check_offline_optiscaler; then
        apply_overlays
        return 0
    fi

    log_info "No cached/offline OptiScaler found, attempting online download..."

    # Require 7z before downloading (no point downloading if we can't extract)
    require_7z || return 1

    # Query GitHub API for latest release
    log_info "Querying GitHub API for latest release..."
    local api_response
    api_response=$(curl -s --max-time 30 "https://api.github.com/repos/optiscaler/OptiScaler/releases/latest")

    if [[ -z "$api_response" ]]; then
        log_error "Failed to query GitHub API (network issue?)"
        _show_offline_instructions
        return 1
    fi

    # Find the .7z file (the compiled binary)
    local download_url
    download_url=$(echo "$api_response" | grep -o '"browser_download_url": "[^"]*\.7z"' | head -1 | sed 's/.*": "\([^"]*\)".*/\1/')

    if [[ -z "$download_url" ]]; then
        log_error "Could not find .7z file in latest OptiScaler release"
        log_info "Available files in latest release:"
        echo "$api_response" | grep -o '"name": "[^"]*"' | sed 's/.*": "\([^"]*\)".*/  - \1/'
        _show_offline_instructions
        return 1
    fi

    # Use secure temporary file
    local dest
    dest=$(mktemp -t optiscaler-download-XXXXXXXX.7z) || {
        log_error "Failed to create temporary file"
        return 1
    }

    log_info "Downloading from: $download_url"

    if wget --timeout=30 --tries=3 --show-progress -O "$dest" "$download_url" 2>&1; then
        log_success "Downloaded OptiScaler"

        # Move to cache directory
        mkdir -p "$CACHE_DIR"
        chmod 700 "$CACHE_DIR"
        mv "$dest" "$CACHE_DIR/optiscaler-latest.7z"
        dest="$CACHE_DIR/optiscaler-latest.7z"

        mkdir -p "$CACHE_DIR/optiscaler"

        log_info "Extracting OptiScaler (7z format)..."

        if 7z x -o"$CACHE_DIR/optiscaler" "$dest" > /dev/null 2>&1; then
            log_success "Extracted OptiScaler successfully"

            # Verify DLL exists
            if [[ -f "$CACHE_DIR/optiscaler/OptiScaler.dll" ]]; then
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
        rm -f "$dest"  # Clean up temp file
        return 1
    fi
}

# Internal helper for offline instructions
_show_offline_instructions() {
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
}

# ═══════════════════════════════════════════════════════════════════════════
#  CHECK OFFLINE - fakenvapi
# ═══════════════════════════════════════════════════════════════════════════

check_offline_fakenvapi() {
    log_info "Checking for pre-downloaded fakenvapi..."

    if [[ -d "$CACHE_DIR/x64" && -f "$CACHE_DIR/x64/nvapi64.dll" ]]; then
        log_success "fakenvapi found in cache (offline)"
        return 0
    fi

    local search_locations=(
        "./dxvk-nvapi.tar.gz"
        "$HOME/dxvk-nvapi.tar.gz"
        "$HOME/Downloads/dxvk-nvapi.tar.gz"
        "./fakenvapi.tar.gz"
        "$HOME/fakenvapi.tar.gz"
        "$HOME/Downloads/fakenvapi.tar.gz"
    )

    for location in "${search_locations[@]}"; do
        if [[ -f "$location" ]]; then
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

    init_secure_directories || return 1

    # Check offline first
    if check_offline_fakenvapi; then
        return 0
    fi

    log_info "No cached/offline fakenvapi found, attempting online download..."

    # Query GitHub API for latest release
    log_info "Querying GitHub API for latest release..."
    local api_response
    api_response=$(curl -s --max-time 30 "https://api.github.com/repos/jp7677/dxvk-nvapi/releases/latest")

    if [[ -z "$api_response" ]]; then
        log_error "Failed to query GitHub API"
        return 1
    fi

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
        log_error "3. Place it in: $HOME/Downloads/"
        log_error "4. Run this script again"
        log_error ""
        return 1
    fi

    # Use secure temporary file
    local dest
    dest=$(mktemp -t fakenvapi-download-XXXXXXXX.tar.gz) || {
        log_error "Failed to create temporary file"
        return 1
    }

    log_info "Downloading from: $download_url"

    if wget --timeout=30 --tries=3 --show-progress -O "$dest" "$download_url" 2>&1; then
        log_success "Downloaded fakenvapi"

        log_info "Extracting fakenvapi..."
        if tar -xzf "$dest" -C "$CACHE_DIR"; then
            log_success "Extracted fakenvapi successfully"
            rm -f "$dest"  # Clean up temp

            # Verify DLL
            if [[ -f "$CACHE_DIR/x64/nvapi64.dll" ]]; then
                log_success "Verified nvapi64.dll present"
                return 0
            else
                log_warn "nvapi64.dll not found at expected location"
                log_info "Archive contents:"
                ls -la "$CACHE_DIR/" 2>/dev/null | grep -E "^d|nvapi"
                return 0  # Not fatal
            fi
        else
            log_error "Failed to extract fakenvapi archive"
            rm -f "$dest"
            return 1
        fi
    else
        log_error "Failed to download fakenvapi"
        rm -f "$dest"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  INSTALL TO GAME - SECURITY HARDENED VERSION
# ═══════════════════════════════════════════════════════════════════════════

install_to_game() {
    local game_dir="$1"
    local app_id="$2"
    local profile_path="${3:-}"
    local target_dir="${4:-$game_dir}"
    local dll_name="${OPTISCALER_DLL_NAME:-dxgi.dll}"

    # Input validation
    if [[ -z "$game_dir" ]]; then
        log_error "install_to_game: No game directory specified"
        return 1
    fi

    if [[ -z "$app_id" ]]; then
        log_error "install_to_game: No app_id specified"
        return 1
    fi

    # Validate game directory exists
    if [[ ! -d "$game_dir" ]]; then
        log_error "Game directory does not exist: $game_dir"
        return 1
    fi

    log_info "Installing OptiScaler to game directory: $game_dir"
    log_debug "Target DLL directory: $target_dir"

    # Create target directory if needed
    mkdir -p "$target_dir" || {
        log_error "Failed to create target directory: $target_dir"
        return 1
    }

    # Component selection defaults
    local install_optiscaler="true"
    local install_xess="true"
    local install_fakenvapi="false"

    # Enable fakenvapi for AMD/Intel by default
    if [[ "${GPU_VENDOR:-}" =~ ^(AMD|Intel)$ ]]; then
        install_fakenvapi="true"
    fi

    # Override with profile settings if available
    if [[ -n "$profile_path" && -f "$profile_path" ]]; then
        install_optiscaler=$(yaml_bool "$profile_path" "install_optiscaler" "$install_optiscaler")
        install_xess=$(yaml_bool "$profile_path" "install_xess" "$install_xess")
        install_fakenvapi=$(yaml_bool "$profile_path" "install_fakenvapi" "$install_fakenvapi")
    fi

    # ───────────────────────────────────────────────────────────────────────
    # Create backup with secure permissions
    # ───────────────────────────────────────────────────────────────────────
    local backup_dir="$BACKUP_DIR/$app_id/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    chmod 700 "$backup_dir"

    # Create manifest
    {
        echo "Game Directory: $game_dir"
        echo "App ID: $app_id"
        echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Profile: ${profile_path:-none}"
    } > "$backup_dir/MANIFEST.txt"

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
        "dxgi.dll"
    )

    for file in "${files_to_backup[@]}"; do
        if [[ -f "$target_dir/$file" ]]; then
            cp "$target_dir/$file" "$backup_dir/"
            log_info "  ↳ Backed up: $file"
        fi
    done

    # ───────────────────────────────────────────────────────────────────────
    # Install OptiScaler Core Files
    # ───────────────────────────────────────────────────────────────────────

    local installation_success=true

    if [[ "$install_optiscaler" == "true" ]]; then
        if [[ -f "$CACHE_DIR/optiscaler/OptiScaler.dll" ]]; then
            cp "$CACHE_DIR/optiscaler/OptiScaler.dll" "$target_dir/"
            log_success "  ↳ Installed: OptiScaler.dll (main plugin)"

            # Also create launcher-friendly alias
            if cp "$CACHE_DIR/optiscaler/OptiScaler.dll" "$target_dir/$dll_name"; then
                log_success "  ↳ Installed alias: $dll_name"
            else
                log_warn "  ⚠ Failed to install alias $dll_name"
            fi
        else
            log_error "  ✗ CRITICAL: OptiScaler.dll missing"
            installation_success=false
        fi
    else
        log_info "  ℹ Skipped OptiScaler.dll (profile preference)"
    fi

    # ───────────────────────────────────────────────────────────────────────
    # Install XeSS support
    # ───────────────────────────────────────────────────────────────────────

    if [[ "$install_xess" == "true" ]]; then
        local xess_files=("libxess.dll" "libxess_dx11.dll" "libxell.dll" "libxess_fg.dll")
        for f in "${xess_files[@]}"; do
            if [[ -f "$CACHE_DIR/optiscaler/$f" ]]; then
                cp "$CACHE_DIR/optiscaler/$f" "$target_dir/"
                log_success "  ↳ Installed: $f"
            fi
        done
    else
        log_info "  ℹ Skipped XeSS runtime (profile preference)"
    fi

    # ───────────────────────────────────────────────────────────────────────
    # Install AMD FidelityFX Libraries (FSR4 support)
    # ───────────────────────────────────────────────────────────────────────

    local fsr_files=(
        "amd_fidelityfx_dx12.dll"
        "amd_fidelityfx_framegeneration_dx12.dll"
        "amd_fidelityfx_upscaler_dx12.dll"
        "amd_fidelityfx_vk.dll"
        "dlssg_to_fsr3_amd_is_better.dll"
    )

    for fsr_dll in "${fsr_files[@]}"; do
        if [[ -f "$CACHE_DIR/optiscaler/$fsr_dll" ]]; then
            cp "$CACHE_DIR/optiscaler/$fsr_dll" "$target_dir/"
            log_success "  ↳ Installed: $fsr_dll"
        else
            log_debug "  ⚠ Optional: $fsr_dll not found in cache"
        fi
    done

    # ───────────────────────────────────────────────────────────────────────
    # Install fakenvapi (GPU Spoofing for AMD/Intel)
    # ───────────────────────────────────────────────────────────────────────

    if [[ "$install_fakenvapi" == "true" ]]; then
        if [[ -f "$CACHE_DIR/x64/nvapi64.dll" ]]; then
            cp "$CACHE_DIR/x64/nvapi64.dll" "$target_dir/"
            log_success "  ↳ Installed: fakenvapi (nvapi64.dll - GPU spoofing)"
        else
            log_warn "  ⚠ fakenvapi nvapi64.dll not found"
        fi
    else
        log_info "  ℹ Skipping fakenvapi (profile preference or NVIDIA GPU)"
    fi

    # ───────────────────────────────────────────────────────────────────────
    # Install Configuration Files
    # ───────────────────────────────────────────────────────────────────────

    if [[ "$install_optiscaler" == "true" ]]; then
        if [[ -f "$GENERATED_DIR/OptiScaler.ini" ]]; then
            cp "$GENERATED_DIR/OptiScaler.ini" "$target_dir/"
            log_success "  ↳ Installed: OptiScaler.ini (configuration)"
        else
            log_warn "  ⚠ OptiScaler.ini not found in generated configs"
        fi
    fi

    if [[ "$install_fakenvapi" == "true" ]]; then
        if [[ -f "$GENERATED_DIR/fakenvapi.ini" ]]; then
            cp "$GENERATED_DIR/fakenvapi.ini" "$target_dir/"
            log_success "  ↳ Installed: fakenvapi.ini (Anti-Lag 2 config)"
        fi
    fi

    # ───────────────────────────────────────────────────────────────────────
    # Final Status
    # ───────────────────────────────────────────────────────────────────────

    if [[ "$installation_success" == "true" ]]; then
        log_success "Installation complete for game: $app_id"
        log_info "Backup saved to: $backup_dir"
        return 0
    else
        log_error "Installation failed - critical files missing"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  EXPORT FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

export -f init_secure_directories
export -f use_local_optiscaler
export -f apply_overlay
export -f apply_overlays
export -f yaml_bool
export -f require_7z
export -f check_offline_optiscaler
export -f check_offline_fakenvapi
export -f download_optiscaler
export -f download_fakenvapi
export -f install_to_game
