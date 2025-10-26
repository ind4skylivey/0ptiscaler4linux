#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - TEST RUNNER
# ═══════════════════════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TESTS_DIR="$SCRIPT_DIR/tests"

source "$SCRIPT_DIR/lib/colors.sh"

TOTAL_PASSED=0
TOTAL_FAILED=0

echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  OPTISCALER UNIVERSAL - TEST SUITE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
echo ""

for test in "$TESTS_DIR"/test-*.sh; do
    if [ -f "$test" ]; then
        test_name=$(basename "$test")
        echo -e "${YELLOW}Running: $test_name${NC}"
        echo ""
        
        if bash "$test"; then
            echo -e "${GREEN}✓ $test_name PASSED${NC}"
            TOTAL_PASSED=$((TOTAL_PASSED + 1))
        else
            echo -e "${RED}✗ $test_name FAILED${NC}"
            TOTAL_FAILED=$((TOTAL_FAILED + 1))
        fi
        
        echo ""
        echo -e "${BLUE}───────────────────────────────────────────────────────────────────────────${NC}"
        echo ""
    fi
done

echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  TEST SUMMARY${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Test Files Passed: $TOTAL_PASSED${NC}"
echo -e "${RED}Test Files Failed: $TOTAL_FAILED${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"

if [ $TOTAL_FAILED -gt 0 ]; then
    exit 1
fi

exit 0
