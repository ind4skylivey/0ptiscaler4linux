#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - MAIN INSTALLER
# ═══════════════════════════════════════════════════════════════════════════
#
#  Intelligent installer that detects GPU and games automatically
#
#  Usage: bash scripts/install.sh
#
# ═══════════════════════════════════════════════════════════════════════════

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source libraries
source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/core/detector.sh"

# ═══════════════════════════════════════════════════════════════════════════
#  BANNER
# ═══════════════════════════════════════════════════════════════════════════

show_banner() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                                                                           ${NC}"
    echo -e "${BLUE}                    OPTISCALER UNIVERSAL INSTALLER                        ${NC}"
    echo -e "${BLUE}                                                                           ${NC}"
    echo -e "${BLUE}           Unlock your GPU's full potential on Linux - automatically      ${NC}"
    echo -e "${BLUE}                                                                           ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}Version: 0.1.0-alpha${NC}"
    echo -e "${CYAN}License: MIT - Open Source${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  REQUIREMENTS CHECK
# ═══════════════════════════════════════════════════════════════════════════

check_requirements() {
    log_section "Checking System Requirements"
    
    local requirements_met=true
    
    # Check bash version
    if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
        log_error "Bash 4.0+ required (found: $BASH_VERSION)"
        requirements_met=false
    else
        log_success "Bash version: $BASH_VERSION"
    fi
    
    # Check required commands
    local required_commands=("lspci" "sed" "awk" "grep")
    for cmd in "${required_commands[@]}"; do
        if command_exists "$cmd"; then
            log_success "$cmd: found"
        else
            log_error "$cmd: not found"
            requirements_met=false
        fi
    done
    
    # Check optional but recommended
    if command_exists "python3"; then
        log_success "python3: found (for YAML parsing)"
    else
        log_warn "python3: not found (YAML parsing will be limited)"
    fi
    
    if $requirements_met; then
        log_info "All requirements met"
        return 0
    else
        log_error "Some requirements are missing"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  MAIN INSTALLATION FLOW
# ═══════════════════════════════════════════════════════════════════════════

main() {
    show_banner
    
    log_info "Starting OptiScaler Universal installation..."
    echo ""
    
    # Step 1: Check requirements
    if ! check_requirements; then
        log_error_exit "System requirements not met. Please install missing packages."
    fi
    echo ""
    
    # Step 2: Detect GPU
    log_section "Detecting GPU Configuration"
    if ! detect_gpu; then
        log_error_exit "GPU detection failed"
    fi
    echo ""
    
    # Step 3: Show detected configuration
    log_section "Detected Configuration"
    echo -e "${CYAN}GPU Vendor:${NC}      $GPU_VENDOR"
    echo -e "${CYAN}Architecture:${NC}    $GPU_ARCHITECTURE"
    echo -e "${CYAN}Generation:${NC}      $GPU_GENERATION"
    echo -e "${CYAN}Model:${NC}           $GPU_MODEL"
    echo -e "${CYAN}Capabilities:${NC}    ${GPU_CAPABILITIES[*]}"
    echo ""
    
    # Get recommended profile
    local gpu_profile=$(get_gpu_profile_name)
    echo -e "${GREEN}Recommended GPU Profile:${NC} $gpu_profile"
    echo ""
    
    # Step 4: Validate GPU requirements
    if ! validate_gpu_requirements; then
        log_warn "Some GPU requirements not met, but continuing..."
    fi
    echo ""
    
    # Step 5: Scan for games
    log_section "Scanning for Supported Games"
    source "$SCRIPT_DIR/core/game-scanner.sh"
    scan_steam_games
    echo ""
    
    display_found_games
    echo ""
    
    # Step 6: Generate configs
    if [ ${#FOUND_GAMES[@]} -gt 0 ]; then
        log_section "Configuration Generation"
        
        source "$SCRIPT_DIR/core/configurator.sh"
        
        local config_dir="$HOME/.optiscaler-universal/generated"
        mkdir -p "$config_dir"
        
        generate_optiscaler_ini "$gpu_profile" "$config_dir/OptiScaler.ini"
        generate_fakenvapi_ini "$config_dir/fakenvapi.ini"
        
        echo ""
        log_success "Configuration files generated in: $config_dir"
        echo ""
    fi
    
    # Step 7: Show next steps
    log_section "Installation Complete - Next Steps"
    echo ""
    echo -e "${GREEN}✓ GPU Detected: $GPU_VENDOR $GPU_GENERATION${NC}"
    echo -e "${GREEN}✓ Found ${#FOUND_GAMES[@]} supported game(s)${NC}"
    echo -e "${GREEN}✓ Configuration files generated${NC}"
    echo ""
    echo -e "${YELLOW}To complete setup:${NC}"
    echo ""
    echo "1. Copy generated configs to your game directory:"
    echo "   ${CYAN}cp ~/.optiscaler-universal/generated/*.ini \"\$GAME_DIR/Bin64/\"${NC}"
    echo ""
    echo "2. Configure Steam Launch Options:"
    echo "   ${GREEN}WINEDLLOVERRIDES=dxgi.dll=n,b PROTON_FSR4_UPGRADE=1 %command%${NC}"
    echo ""
    echo "3. In-game settings:"
    echo "   - Upscaling: ${GREEN}DLSS Quality${NC}"
    echo "   - NVIDIA Reflex: ${GREEN}On + Boost${NC}"
    echo ""
    log_success "Setup complete! Ready to game!"
    echo ""
}

# Run main
main "$@"
