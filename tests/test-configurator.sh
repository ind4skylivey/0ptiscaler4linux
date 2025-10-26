#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - CONFIGURATOR TESTS
# ═══════════════════════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/core/configurator.sh"

TESTS_PASSED=0
TESTS_FAILED=0
TEST_OUTPUT_DIR="/tmp/optiscaler_test_$$"

# ═══════════════════════════════════════════════════════════════════════════
#  SETUP/TEARDOWN
# ═══════════════════════════════════════════════════════════════════════════

setup() {
    mkdir -p "$TEST_OUTPUT_DIR"
}

teardown() {
    rm -rf "$TEST_OUTPUT_DIR"
}

# ═══════════════════════════════════════════════════════════════════════════
#  TEST FRAMEWORK
# ═══════════════════════════════════════════════════════════════════════════

assert_file_exists() {
    local file="$1"
    local message="$2"
    
    if [ -f "$file" ]; then
        log_success "✓ $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "✗ $message (file not found: $file)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local message="$3"
    
    if grep -q "$pattern" "$file"; then
        log_success "✓ $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "✗ $message (pattern not found: $pattern)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  TESTS
# ═══════════════════════════════════════════════════════════════════════════

test_optiscaler_generation() {
    echo -e "${CYAN}TEST:${NC} OptiScaler.ini Generation"
    
    local output_file="$TEST_OUTPUT_DIR/OptiScaler.ini"
    generate_optiscaler_ini "amd-rdna3" "$output_file"
    
    assert_file_exists "$output_file" "OptiScaler.ini created"
    assert_file_contains "$output_file" "\[General\]" "Contains [General] section"
    assert_file_contains "$output_file" "\[Upscalers\]" "Contains [Upscalers] section"
    assert_file_contains "$output_file" "\[FSR\]" "Contains [FSR] section"
    
    echo ""
}

test_fakenvapi_generation() {
    echo -e "${CYAN}TEST:${NC} fakenvapi.ini Generation"
    
    local output_file="$TEST_OUTPUT_DIR/fakenvapi.ini"
    generate_fakenvapi_ini "$output_file"
    
    assert_file_exists "$output_file" "fakenvapi.ini created"
    assert_file_contains "$output_file" "\[General\]" "Contains [General] section"
    assert_file_contains "$output_file" "\[Reflex\]" "Contains [Reflex] section"
    
    echo ""
}

test_template_loading() {
    echo -e "${CYAN}TEST:${NC} Template Loading"
    
    local optiscaler_template="$SCRIPT_DIR/templates/OptiScaler.ini.template"
    local fakenvapi_template="$SCRIPT_DIR/templates/fakenvapi.ini.template"
    
    assert_file_exists "$optiscaler_template" "OptiScaler template exists"
    assert_file_exists "$fakenvapi_template" "fakenvapi template exists"
    
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════════════════

main() {
    setup
    
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  CONFIGURATOR TEST SUITE${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    test_template_loading
    test_optiscaler_generation
    test_fakenvapi_generation
    
    teardown
    
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
