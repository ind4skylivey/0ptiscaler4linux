#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - UPSCALER SELECTOR
# ═══════════════════════════════════════════════════════════════════════════
#
#  Intelligent upscaler selection based on GPU capabilities
#  OptiScaler can force FSR4 on older GPUs via software upscaling
#
# ═══════════════════════════════════════════════════════════════════════════

setup_auto_configuration() {
    log_info "Auto-detecting optimal configuration for your GPU..."
    echo ""
    
    # FSR4 Configuration - OptiScaler can force FSR4 even on RDNA2
    if [[ "$GPU_GENERATION" == "RDNA4" ]]; then
        SELECTED_UPSCALER="fsr4"
        SELECTED_UPSCALER_INPUT="fsr31"
        ENABLE_FRAME_GEN="true"
        log_success "Selected: FSR 4 (native RDNA4 hardware support)"
        log_info "  Hardware-accelerated FSR4 with frame generation"
    
    elif [[ "$GPU_GENERATION" == "RDNA3" ]]; then
        if [[ " ${GPU_CAPABILITIES[@]} " =~ " FSR4_COMPATIBLE " ]]; then
            SELECTED_UPSCALER="fsr4"
            SELECTED_UPSCALER_INPUT="dlss"
            ENABLE_FRAME_GEN="true"
            log_success "Selected: FSR 4 with DLSS inputs (OptiScaler software mode)"
            log_info "  FSR4 forced via OptiScaler + DLSS inputs for best quality"
        else
            SELECTED_UPSCALER="fsr31_12"
            SELECTED_UPSCALER_INPUT="dlss"
            ENABLE_FRAME_GEN="true"
            log_success "Selected: FSR 3.1 with DLSS inputs (RDNA3)"
        fi
    
    elif [[ "$GPU_GENERATION" == "RDNA2" ]]; then
        if [[ " ${GPU_CAPABILITIES[@]} " =~ " FSR4_COMPATIBLE " ]]; then
            SELECTED_UPSCALER="fsr4"
            SELECTED_UPSCALER_INPUT="dlss"
            ENABLE_FRAME_GEN="true"
            log_success "Selected: FSR 4 with DLSS inputs (OptiScaler software mode)"
            log_info "  Your RX 6700 XT can use FSR4 via OptiScaler software upscaling"
            log_info "  DLSS inputs + Anti-Lag 2 for maximum performance"
        else
            SELECTED_UPSCALER="fsr31_12"
            SELECTED_UPSCALER_INPUT="dlss"
            ENABLE_FRAME_GEN="true"
            log_success "Selected: FSR 3.1 with DLSS inputs (RDNA2)"
            log_info "  Reliable FSR3.1 + frame generation + Anti-Lag 2"
        fi
    
    elif [[ "$GPU_GENERATION" == "RDNA1" ]]; then
        SELECTED_UPSCALER="fsr31_12"
        SELECTED_UPSCALER_INPUT="fsr31"
        ENABLE_FRAME_GEN="false"
        log_success "Selected: FSR 3.1 (RDNA1 - no frame generation)"
        log_info "  FSR3.1 upscaling + Anti-Lag"
    
    elif [[ "$GPU_VENDOR" == "Intel" ]] && [[ " ${GPU_CAPABILITIES[@]} " =~ " XESS_SW " ]]; then
        SELECTED_UPSCALER="xess"
        SELECTED_UPSCALER_INPUT="xess"
        ENABLE_FRAME_GEN="false"
        log_success "Selected: XeSS (native Intel Arc support)"
        log_info "  Native XeSS upscaling with DP4a acceleration"
    
    elif [[ "$GPU_VENDOR" == "NVIDIA" ]]; then
        SELECTED_UPSCALER="dlss"
        SELECTED_UPSCALER_INPUT="dlss"
        ENABLE_FRAME_GEN="false"
        log_success "Selected: DLSS (native NVIDIA RTX support)"
        log_info "  Native DLSS + Reflex for lowest latency"
    
    else
        SELECTED_UPSCALER="fsr31_12"
        SELECTED_UPSCALER_INPUT="fsr31"
        ENABLE_FRAME_GEN="false"
        log_success "Selected: FSR 3.1 (universal compatibility)"
        log_info "  Safe fallback for maximum compatibility"
    fi
    
    echo ""
    echo -e "${CYAN}Auto-Configuration Summary:${NC}"
    echo -e "  GPU:             ${GREEN}$GPU_VENDOR $GPU_GENERATION${NC}"
    echo -e "  Upscaler Output: ${GREEN}${SELECTED_UPSCALER^^}${NC}"
    echo -e "  Upscaler Input:  ${GREEN}${SELECTED_UPSCALER_INPUT^^}${NC}"
    echo -e "  Frame Gen:       ${GREEN}${ENABLE_FRAME_GEN}${NC}"
    
    if [[ "$GPU_VENDOR" == "AMD" ]]; then
        echo -e "  Anti-Lag:        ${GREEN}Anti-Lag 2${NC}"
        echo -e "  GPU Spoofing:    ${GREEN}Enabled (RTX 4090)${NC}"
    fi
    
    echo ""
}

select_upscaler_mode() {
    log_info "Using automatic upscaler configuration..."
    setup_auto_configuration
}

export -f setup_auto_configuration
export -f select_upscaler_mode

