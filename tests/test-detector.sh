#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - GPU DETECTOR TESTS
# ═══════════════════════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/core/detector.sh"

TESTS_PASSED=0
TESTS_FAILED=0

# ═══════════════════════════════════════════════════════════════════════════
#  TEST FRAMEWORK
# ═══════════════════════════════════════════════════════════════════════════

test_case() {
    local test_name="$1"
    echo -e "${CYAN}TEST:${NC} $test_name"
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    
    if [ "$expected" = "$actual" ]; then
        log_success "✓ $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "✗ $message"
        log_error "  Expected: $expected"
        log_error "  Actual:   $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_not_empty() {
    local value="$1"
    local message="$2"
    
    if [ -n "$value" ]; then
        log_success "✓ $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "✗ $message (value is empty)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  TESTS
# ═══════════════════════════════════════════════════════════════════════════

test_gpu_detection() {
    test_case "GPU Detection"
    
    if detect_gpu; then
        assert_not_empty "$GPU_VENDOR" "GPU vendor detected"
        assert_not_empty "$GPU_ARCHITECTURE" "GPU architecture detected"
        assert_not_empty "$GPU_GENERATION" "GPU generation detected"
        assert_not_empty "$GPU_MODEL" "GPU model detected"
    else
        log_error "GPU detection failed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    echo ""
}

test_profile_selection() {
    test_case "GPU Profile Selection"
    
    detect_gpu
    local profile=$(get_gpu_profile_name)
    
    assert_not_empty "$profile" "GPU profile name generated"
    
    local profile_file="$SCRIPT_DIR/profiles/gpu/$profile.yaml"
    if [ -f "$profile_file" ]; then
        log_success "✓ Profile file exists: $profile.yaml"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "✗ Profile file not found: $profile.yaml"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    echo ""
}

test_capabilities() {
    test_case "GPU Capabilities Detection"
    
    detect_gpu
    determine_gpu_capabilities()
    
    log_info "Detected capabilities: ${GPU_CAPABILITIES[*]}"
    
    if [ ${#GPU_CAPABILITIES[@]} -gt 0 ]; then
        log_success "✓ At least one capability detected"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_warn "⚠ No capabilities detected (may be normal for some GPUs)"
    fi
    
    echo ""
}

test_driver_detection() {
    test_case "Driver Detection"
    
    detect_gpu
    detect_driver_info
    
    log_info "Testing driver detection (vendor-specific)"
    
    if [ "$GPU_VENDOR" = "AMD" ] || [ "$GPU_VENDOR" = "Intel" ]; then
        if command -v glxinfo &> /dev/null; then
            log_success "✓ Mesa detection tools available"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            log_warn "⚠ glxinfo not found (install mesa-utils)"
        fi
    elif [ "$GPU_VENDOR" = "NVIDIA" ]; then
        if command -v nvidia-smi &> /dev/null; then
            log_success "✓ NVIDIA tools available"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            log_warn "⚠ nvidia-smi not found"
        fi
    fi
    
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════════════════

main() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  GPU DETECTOR TEST SUITE${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    test_gpu_detection
    test_profile_selection
    test_capabilities
    test_driver_detection
    
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
    
    if [ $TESTS_FAILED -gt 0 ]; then
        exit 1
    fi
    
    exit 0
}

main "$@"
