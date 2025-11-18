#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - DIAGNOSTIC TOOL
# ═══════════════════════════════════════════════════════════════════════════
#
#  Diagnoses issues with OptiScaler installations and system configuration
#
#  Usage: bash scripts/diagnose.sh [OPTIONS]
#  Options:
#    --game <name>         Diagnose specific game
#    --game-dir <path>     Diagnose specific game directory
#    --verbose             Show detailed information
#    --export <file>       Export diagnostics to file
#
# ═══════════════════════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/core/detector.sh"

VERBOSE=false
EXPORT_FILE=""

# ═══════════════════════════════════════════════════════════════════════════
#  DIAGNOSTIC FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

show_banner() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                                                                           ${NC}"
    echo -e "${CYAN}                 OPTISCALER UNIVERSAL DIAGNOSTIC TOOL                     ${NC}"
    echo -e "${CYAN}                                                                           ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

check_system_info() {
    log_section "System Information"
    
    echo -e "${CYAN}Operating System:${NC} $(uname -o)"
    echo -e "${CYAN}Kernel:${NC}           $(uname -r)"
    echo -e "${CYAN}Architecture:${NC}     $(uname -m)"
    echo -e "${CYAN}Hostname:${NC}         $(hostname)"
    echo ""
    
    if [ "$VERBOSE" = true ]; then
        echo -e "${CYAN}CPU:${NC}              $(lscpu | grep "Model name" | cut -d: -f2 | xargs)"
        echo -e "${CYAN}Memory:${NC}           $(free -h | awk '/^Mem:/ {print $2}')"
        echo ""
    fi
}

check_gpu_info() {
    log_section "GPU Detection"
    
    detect_gpu
    
    echo -e "${CYAN}Vendor:${NC}           $GPU_VENDOR"
    echo -e "${CYAN}Architecture:${NC}     $GPU_ARCHITECTURE"
    echo -e "${CYAN}Generation:${NC}       $GPU_GENERATION"
    echo -e "${CYAN}Model:${NC}            $GPU_MODEL"
    echo -e "${CYAN}Capabilities:${NC}     ${GPU_CAPABILITIES[*]}"
    echo ""
}

check_driver_info() {
    log_section "Driver Information"
    
    if [ "$GPU_VENDOR" = "AMD" ] || [ "$GPU_VENDOR" = "Intel" ]; then
        if command -v glxinfo &> /dev/null; then
            local mesa_version=$(glxinfo | grep "OpenGL version string" | cut -d: -f2 | xargs)
            echo -e "${CYAN}Mesa Version:${NC}     $mesa_version"
            
            local required_version="25.2.0"
            echo -e "${CYAN}Required Mesa:${NC}    $required_version+"
            echo ""
            
            if [ -n "$mesa_version" ]; then
                log_success "Mesa driver detected"
            else
                log_warn "Could not detect Mesa version"
            fi
        else
            log_warn "glxinfo not found (install mesa-utils)"
        fi
        
        if [ "$VERBOSE" = true ]; then
            echo -e "${CYAN}AMDGPU Info:${NC}"
            if command -v radeontop &> /dev/null; then
                radeontop -d- -l 1 2>/dev/null | grep -E "gpu|vram" || echo "  (radeontop check failed)"
            else
                echo "  (radeontop not installed)"
            fi
            echo ""
        fi
        
    elif [ "$GPU_VENDOR" = "NVIDIA" ]; then
        if command -v nvidia-smi &> /dev/null; then
            local nvidia_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null || echo "Unknown")
            echo -e "${CYAN}NVIDIA Driver:${NC}    $nvidia_version"
            
            local required_version="550.0"
            echo -e "${CYAN}Required Driver:${NC}  $required_version+"
            echo ""
            
            log_success "NVIDIA driver detected"
            
            if [ "$VERBOSE" = true ]; then
                echo -e "${CYAN}GPU Details:${NC}"
                nvidia-smi --query-gpu=name,memory.total,compute_cap --format=csv,noheader 2>/dev/null || echo "  (query failed)"
                echo ""
            fi
        else
            log_warn "nvidia-smi not found"
        fi
    fi
}

check_proton_info() {
    log_section "Proton/Wine Information"
    
    local steam_root="$HOME/.local/share/Steam"
    
    if [ -d "$steam_root" ]; then
        log_success "Steam installation found"
        
        local compattools="$steam_root/compatibilitytools.d"
        if [ -d "$compattools" ]; then
            echo -e "${CYAN}Installed Proton versions:${NC}"
            ls -1 "$compattools" 2>/dev/null | grep -E "Proton|GE" | head -10 || echo "  (none found)"
            echo ""
        fi
        
        if [ "$VERBOSE" = true ]; then
            echo -e "${CYAN}Steam Library Locations:${NC}"
            if [ -f "$steam_root/steamapps/libraryfolders.vdf" ]; then
                grep '"path"' "$steam_root/steamapps/libraryfolders.vdf" | cut -d'"' -f4 || echo "  (parse failed)"
            fi
            echo ""
        fi
    else
        log_warn "Steam not found at: $steam_root"
    fi
}

check_game_installation() {
    local game_dir="$1"
    
    log_section "Game Installation Check: $game_dir"
    
    if [ ! -d "$game_dir" ]; then
        log_error "Directory not found: $game_dir"
        return 1
    fi
    
    local files=(
        "dxgi.dll|OptiScaler DLL|Critical"
        "OptiScaler.ini|Configuration|Critical"
        "nvapi64.dll|fakenvapi DLL|Optional (AMD only)"
        "fakenvapi.ini|fakenvapi Config|Optional (AMD only)"
    )
    
    echo -e "${CYAN}OptiScaler Files:${NC}"
    for entry in "${files[@]}"; do
        IFS='|' read -r file desc importance <<< "$entry"
        local file_path="$game_dir/$file"
        
        if [ -f "$file_path" ]; then
            local size=$(du -h "$file_path" | cut -f1)
            log_success "✓ $desc ($file) - $size"
            
            if [ "$VERBOSE" = true ]; then
                echo "    Path: $file_path"
                echo "    Modified: $(stat -c %y "$file_path" | cut -d. -f1)"
            fi
        else
            if [[ "$importance" == *"Critical"* ]]; then
                log_error "✗ $desc ($file) - MISSING ($importance)"
            else
                log_warn "○ $desc ($file) - Not present ($importance)"
            fi
        fi
    done
    echo ""
    
    if [ "$VERBOSE" = true ] && [ -f "$game_dir/OptiScaler.ini" ]; then
        echo -e "${CYAN}OptiScaler Configuration:${NC}"
        grep -E "^(Dx12Upscaler|Dx11Upscaler|VulkanUpscaler|OverrideNvapiDll)" "$game_dir/OptiScaler.ini" 2>/dev/null || echo "  (parse failed)"
        echo ""
    fi
    
    if [ -f "$game_dir/OptiScaler.log" ]; then
        log_info "Log file found: OptiScaler.log"
        
        local log_size=$(du -h "$game_dir/OptiScaler.log" | cut -f1)
        echo "  Size: $log_size"
        
        local last_error=$(grep -i "error" "$game_dir/OptiScaler.log" | tail -1)
        if [ -n "$last_error" ]; then
            log_warn "Last error in log:"
            echo "  $last_error"
        fi
        echo ""
    fi
}

check_common_issues() {
    log_section "Common Issues Check"
    
    local issues_found=0
    
    if ! validate_gpu_requirements; then
        log_warn "GPU requirements not fully met"
        issues_found=$((issues_found + 1))
    fi
    
    if [ "$GPU_VENDOR" = "AMD" ] || [ "$GPU_VENDOR" = "Intel" ]; then
        if ! command -v glxinfo &> /dev/null; then
            log_warn "mesa-utils not installed (recommended for diagnostics)"
            issues_found=$((issues_found + 1))
        fi
    fi
    
    if [ ! -d "$HOME/.local/share/Steam" ]; then
        log_warn "Steam not found in default location"
        issues_found=$((issues_found + 1))
    fi
    
    if [ $issues_found -eq 0 ]; then
        log_success "No common issues detected"
    else
        echo ""
        log_info "Found $issues_found potential issue(s)"
    fi
    echo ""
}

show_recommendations() {
    log_section "Recommendations"
    
    if [ "$GPU_VENDOR" = "AMD" ]; then
        echo "• Ensure Mesa 25.2.0+ is installed"
        echo "• Enable fakenvapi (nvapi64.dll) for Anti-Lag 2 support"
        echo "• Use FSR3.1 upscaler for best performance"
    elif [ "$GPU_VENDOR" = "Intel" ]; then
        echo "• Ensure Mesa 25.2.0+ is installed"
        echo "• Use XeSS upscaler if available (Arc GPUs)"
        echo "• Consider FSR3.1 fallback for integrated graphics"
    elif [ "$GPU_VENDOR" = "NVIDIA" ]; then
        echo "• Ensure driver version 550+ is installed"
        echo "• Native DLSS is recommended"
        echo "• OptiScaler is optional for NVIDIA GPUs"
    fi
    
    echo ""
    echo "General:"
    echo "• Check game logs in game directory"
    echo "• Use Proton-EM or GE-Proton for FSR4 support"
    echo "• Set WINEDLLOVERRIDES=dxgi.dll=n,b in Steam launch options"
    echo "• Enable NVIDIA Reflex in-game (becomes Anti-Lag 2 on AMD)"
    echo ""
}

export_diagnostics() {
    local export_file="$1"
    
    log_info "Exporting diagnostics to: $export_file"
    
    {
        echo "OptiScaler Universal - Diagnostic Report"
        echo "Generated: $(date)"
        echo "═══════════════════════════════════════════════════════════════════════════"
        echo ""
        
        echo "SYSTEM INFORMATION"
        echo "─────────────────"
        echo "OS: $(uname -o)"
        echo "Kernel: $(uname -r)"
        echo "Architecture: $(uname -m)"
        echo ""
        
        echo "GPU INFORMATION"
        echo "───────────────"
        echo "Vendor: $GPU_VENDOR"
        echo "Architecture: $GPU_ARCHITECTURE"
        echo "Generation: $GPU_GENERATION"
        echo "Model: $GPU_MODEL"
        echo "Capabilities: ${GPU_CAPABILITIES[*]}"
        echo ""
        
        echo "DRIVER INFORMATION"
        echo "──────────────────"
        if [ "$GPU_VENDOR" = "AMD" ] || [ "$GPU_VENDOR" = "Intel" ]; then
            echo "Mesa Version: $(glxinfo 2>/dev/null | grep "OpenGL version string" | cut -d: -f2 | xargs || echo "Unknown")"
        elif [ "$GPU_VENDOR" = "NVIDIA" ]; then
            echo "NVIDIA Driver: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null || echo "Unknown")"
        fi
        echo ""
        
        echo "═══════════════════════════════════════════════════════════════════════════"
        
    } > "$export_file"
    
    log_success "Diagnostics exported successfully"
}

# ═══════════════════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════════════════

main() {
    local game_name=""
    local game_dir=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --game)
                game_name="$2"
                shift 2
                ;;
            --game-dir)
                game_dir="$2"
                shift 2
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --export)
                EXPORT_FILE="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    show_banner
    
    check_system_info
    check_gpu_info
    check_driver_info
    check_proton_info
    
    if [ -n "$game_dir" ]; then
        check_game_installation "$game_dir"
    elif [ -n "$game_name" ]; then
        log_info "Searching for game: $game_name"
        source "$SCRIPT_DIR/core/game-scanner.sh"
        scan_steam_games
        
        for i in "${!FOUND_GAMES[@]}"; do
            if [[ "${FOUND_GAMES[$i]}" == *"$game_name"* ]]; then
                local game_info="${FOUND_GAMES[$i]}"
                local dir=$(echo "$game_info" | cut -d'|' -f3)
                check_game_installation "$dir"
                break
            fi
        done
    fi
    
    check_common_issues
    show_recommendations
    
    if [ -n "$EXPORT_FILE" ]; then
        export_diagnostics "$EXPORT_FILE"
    fi
    
    log_success "Diagnostics complete"
}

main "$@"
