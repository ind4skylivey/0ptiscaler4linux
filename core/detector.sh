#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - GPU DETECTOR
# ═══════════════════════════════════════════════════════════════════════════
#
#  Automatically detects GPU vendor, architecture, and capabilities
#
#  Usage: source core/detector.sh && detect_gpu
#
# ═══════════════════════════════════════════════════════════════════════════

# Global variables for detected GPU info
GPU_VENDOR=""
GPU_ARCHITECTURE=""
GPU_GENERATION=""
GPU_MODEL=""
GPU_CAPABILITIES=()

# ═══════════════════════════════════════════════════════════════════════════
#  Main GPU Detection Function
# ═══════════════════════════════════════════════════════════════════════════

detect_gpu() {
    log_info "Detecting GPU configuration..."
    
    # Get GPU info from lspci
    local gpu_info
    gpu_info=$(lspci 2>/dev/null | grep -i 'vga\|3d\|display' | head -1)
    
    if [ -z "$gpu_info" ]; then
        # Check if we're in CI environment
        if [ -n "$CI" ] || [ -n "$GITHUB_ACTIONS" ]; then
            log_warn "No GPU detected (CI environment) - using mock GPU for testing"
            GPU_VENDOR="AMD"
            GPU_ARCHITECTURE="RDNA"
            GPU_GENERATION="RDNA3"
            GPU_MODEL="Mock GPU for CI Testing"
            GPU_CAPABILITIES=("FSR3" "FSR4_COMPATIBLE" "ANTI_LAG_2" "XESS_SW" "DLSS_INPUTS_RECOMMENDED")
            return 0
        else
            log_error "No GPU detected via lspci"
            return 1
        fi
    fi
    
    log_debug "Raw GPU info: $gpu_info"
    
    # Determine vendor
    if echo "$gpu_info" | grep -iq "amd\|radeon\|ati"; then
        detect_amd_gpu "$gpu_info"
    elif echo "$gpu_info" | grep -iq "intel"; then
        detect_intel_gpu "$gpu_info"
    elif echo "$gpu_info" | grep -iq "nvidia\|geforce\|quadro"; then
        detect_nvidia_gpu "$gpu_info"
    else
        GPU_VENDOR="Unknown"
        GPU_ARCHITECTURE="Unknown"
        GPU_GENERATION="Unknown"
        log_warn "Unknown GPU vendor"
        return 1
    fi
    
    # Detect driver information (skip in CI)
    if [ "$GPU_MODEL" != "Mock GPU for CI Testing" ]; then
        detect_driver_info
    fi
    
    # Determine capabilities
    if [ ${#GPU_CAPABILITIES[@]} -eq 0 ]; then
        determine_gpu_capabilities
    fi
    
    # Log results
    log_info "GPU Detection Results:"
    log_info "  Vendor: $GPU_VENDOR"
    log_info "  Architecture: $GPU_ARCHITECTURE"
    log_info "  Generation: $GPU_GENERATION"
    log_info "  Model: $GPU_MODEL"
    log_info "  Capabilities: ${GPU_CAPABILITIES[*]}"
    
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════
#  AMD GPU Detection
# ═══════════════════════════════════════════════════════════════════════════

detect_amd_gpu() {
    local gpu_info="$1"
    GPU_VENDOR="AMD"
    
    # Extract model name
    GPU_MODEL=$(echo "$gpu_info" | sed 's/.*\[AMD\/ATI\] //; s/ (rev.*)//')
    
    # Determine architecture and generation
    if echo "$gpu_info" | grep -iq "navi 4\|RDNA 4\|RX 9"; then
        GPU_ARCHITECTURE="RDNA"
        GPU_GENERATION="RDNA4"
    elif echo "$gpu_info" | grep -iq "navi 3\|RDNA 3\|RX 7"; then
        GPU_ARCHITECTURE="RDNA"
        GPU_GENERATION="RDNA3"
    elif echo "$gpu_info" | grep -iq "navi 2\|RDNA 2\|RX 6"; then
        GPU_ARCHITECTURE="RDNA"
        GPU_GENERATION="RDNA2"
    elif echo "$gpu_info" | grep -iq "navi 1\|RDNA 1\|RX 5[0-9][0-9][0-9]"; then
        GPU_ARCHITECTURE="RDNA"
        GPU_GENERATION="RDNA1"
    elif echo "$gpu_info" | grep -iq "vega\|RX [4-5][0-9][0-9]"; then
        GPU_ARCHITECTURE="GCN"
        GPU_GENERATION="GCN5"
    elif echo "$gpu_info" | grep -iq "polaris\|RX [4-5][0-9][0-9]"; then
        GPU_ARCHITECTURE="GCN"
        GPU_GENERATION="GCN4"
    else
        GPU_ARCHITECTURE="GCN"
        GPU_GENERATION="GCN"
    fi
    
    log_debug "Detected AMD GPU: $GPU_GENERATION"
}

# ═══════════════════════════════════════════════════════════════════════════
#  Intel GPU Detection
# ═══════════════════════════════════════════════════════════════════════════

detect_intel_gpu() {
    local gpu_info="$1"
    GPU_VENDOR="Intel"
    
    # Extract model name
    GPU_MODEL=$(echo "$gpu_info" | sed 's/.*Intel Corporation //; s/ (rev.*)//')
    
    # Determine if it's Arc or integrated
    if echo "$gpu_info" | grep -iq "arc\|A[3-7][0-9][0-9]"; then
        GPU_ARCHITECTURE="Xe"
        GPU_GENERATION="Arc"
    elif echo "$gpu_info" | grep -iq "iris xe\|xe"; then
        GPU_ARCHITECTURE="Xe"
        GPU_GENERATION="Xe-LP"
    else
        GPU_ARCHITECTURE="Integrated"
        GPU_GENERATION="UHD"
    fi
    
    log_debug "Detected Intel GPU: $GPU_GENERATION"
}

# ═══════════════════════════════════════════════════════════════════════════
#  NVIDIA GPU Detection
# ═══════════════════════════════════════════════════════════════════════════

detect_nvidia_gpu() {
    local gpu_info="$1"
    GPU_VENDOR="NVIDIA"
    
    # Extract model name
    GPU_MODEL=$(echo "$gpu_info" | sed 's/.*NVIDIA Corporation //; s/ (rev.*)//')
    
    # Determine generation
    if echo "$gpu_info" | grep -iq "RTX 50\|GeForce 50"; then
        GPU_ARCHITECTURE="Blackwell"
        GPU_GENERATION="RTX50"
    elif echo "$gpu_info" | grep -iq "RTX 40\|GeForce 40"; then
        GPU_ARCHITECTURE="Ada"
        GPU_GENERATION="RTX40"
    elif echo "$gpu_info" | grep -iq "RTX 30\|GeForce 30"; then
        GPU_ARCHITECTURE="Ampere"
        GPU_GENERATION="RTX30"
    elif echo "$gpu_info" | grep -iq "RTX 20\|GeForce 20"; then
        GPU_ARCHITECTURE="Turing"
        GPU_GENERATION="RTX20"
    elif echo "$gpu_info" | grep -iq "GTX 16"; then
        GPU_ARCHITECTURE="Turing"
        GPU_GENERATION="GTX16"
    elif echo "$gpu_info" | grep -iq "GTX 10"; then
        GPU_ARCHITECTURE="Pascal"
        GPU_GENERATION="GTX10"
    else
        GPU_ARCHITECTURE="Legacy"
        GPU_GENERATION="GTX"
    fi
    
    log_debug "Detected NVIDIA GPU: $GPU_GENERATION"
}

# ═══════════════════════════════════════════════════════════════════════════
#  Driver Detection
# ═══════════════════════════════════════════════════════════════════════════

detect_driver_info() {
    case "$GPU_VENDOR" in
        "AMD"|"Intel")
            # Check Mesa version
            if command -v glxinfo &> /dev/null; then
                MESA_VERSION=$(glxinfo | grep "OpenGL version" | grep -oP 'Mesa \K[0-9.]+' | head -1)
                log_debug "Mesa version: $MESA_VERSION"
            else
                log_warn "glxinfo not found, cannot detect Mesa version"
            fi
            ;;
        "NVIDIA")
            # Check NVIDIA driver version
            if command -v nvidia-smi &> /dev/null; then
                NVIDIA_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1)
                log_debug "NVIDIA driver version: $NVIDIA_VERSION"
            else
                log_warn "nvidia-smi not found, cannot detect NVIDIA driver"
            fi
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════
#  Capability Determination
# ═══════════════════════════════════════════════════════════════════════════

determine_gpu_capabilities() {
    GPU_CAPABILITIES=()
    
    case "$GPU_VENDOR" in
        "AMD")
            # FSR support
            GPU_CAPABILITIES+=("FSR3")
            
            # FSR4 native only on RDNA4
            if [ "$GPU_GENERATION" = "RDNA4" ]; then
                GPU_CAPABILITIES+=("FSR4_NATIVE")
            else
                GPU_CAPABILITIES+=("FSR4_COMPATIBLE")
            fi
            
            # Anti-Lag 2 support on RDNA1+
            if [[ "$GPU_ARCHITECTURE" == "RDNA" ]]; then
                GPU_CAPABILITIES+=("ANTI_LAG_2")
            fi
            
            # XeSS via software
            GPU_CAPABILITIES+=("XESS_SW")
            
            # DLSS inputs recommended
            GPU_CAPABILITIES+=("DLSS_INPUTS_RECOMMENDED")
            ;;
            
        "Intel")
            # FSR support
            GPU_CAPABILITIES+=("FSR3")
            
            # XeSS native on Arc
            if [ "$GPU_GENERATION" = "Arc" ]; then
                GPU_CAPABILITIES+=("XESS_NATIVE")
                GPU_CAPABILITIES+=("DLSS_INPUTS_RECOMMENDED")
            else
                GPU_CAPABILITIES+=("XESS_SW")
            fi
            ;;
            
        "NVIDIA")
            # Native DLSS
            if [[ "$GPU_GENERATION" == RTX* ]]; then
                GPU_CAPABILITIES+=("DLSS_NATIVE")
                GPU_CAPABILITIES+=("REFLEX_NATIVE")
            fi
            
            # FSR support via OptiScaler
            GPU_CAPABILITIES+=("FSR3")
            GPU_CAPABILITIES+=("XESS_SW")
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════
#  Helper Functions
# ═══════════════════════════════════════════════════════════════════════════

get_gpu_profile_name() {
    local profile_name=""
    
    case "$GPU_VENDOR" in
        "AMD")
            case "$GPU_GENERATION" in
                "RDNA4") profile_name="amd-rdna4" ;;
                "RDNA3") profile_name="amd-rdna3" ;;
                "RDNA2") profile_name="amd-rdna2" ;;
                "RDNA1") profile_name="amd-rdna1" ;;
                "GCN"*) profile_name="amd-gcn" ;;
                *) profile_name="generic" ;;
            esac
            ;;
        "Intel")
            case "$GPU_GENERATION" in
                "Arc") profile_name="intel-arc" ;;
                *) profile_name="intel-integrated" ;;
            esac
            ;;
        "NVIDIA")
            profile_name="nvidia-rtx"
            ;;
        *)
            profile_name="generic"
            ;;
    esac
    
    echo "$profile_name"
}

has_capability() {
    local capability="$1"
    for cap in "${GPU_CAPABILITIES[@]}"; do
        if [ "$cap" = "$capability" ]; then
            return 0
        fi
    done
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════
#  Validation
# ═══════════════════════════════════════════════════════════════════════════

validate_gpu_requirements() {
    local requirements_met=true
    
    # Check Mesa version for AMD/Intel
    if [[ "$GPU_VENDOR" == "AMD" || "$GPU_VENDOR" == "Intel" ]]; then
        if [ -n "$MESA_VERSION" ]; then
            # Parse version (e.g., "25.2.5" -> 25)
            local major_version=$(echo "$MESA_VERSION" | cut -d. -f1)
            
            if [ "$major_version" -lt 25 ]; then
                log_warn "Mesa version $MESA_VERSION detected. Mesa 25.2.0+ recommended for FSR4"
                requirements_met=false
            else
                log_info "Mesa version $MESA_VERSION meets requirements"
            fi
        fi
    fi
    
    # Check NVIDIA driver for NVIDIA
    if [ "$GPU_VENDOR" = "NVIDIA" ]; then
        if [ -n "$NVIDIA_VERSION" ]; then
            local major_version=$(echo "$NVIDIA_VERSION" | cut -d. -f1)
            
            if [ "$major_version" -lt 550 ]; then
                log_warn "NVIDIA driver $NVIDIA_VERSION detected. 550+ recommended"
                requirements_met=false
            fi
        fi
    fi
    
    if $requirements_met; then
        return 0
    else
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  Export functions
# ═══════════════════════════════════════════════════════════════════════════

export -f detect_gpu
export -f detect_amd_gpu
export -f detect_intel_gpu
export -f detect_nvidia_gpu
export -f detect_driver_info
export -f determine_gpu_capabilities
export -f get_gpu_profile_name
export -f has_capability
export -f validate_gpu_requirements
