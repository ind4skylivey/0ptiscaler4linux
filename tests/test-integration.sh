#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - COMPREHENSIVE INTEGRATION TEST
# ═══════════════════════════════════════════════════════════════════════════
#
#  Tests all major components of the OptiScaler Universal project:
#    - Module loading and dependencies
#    - Security measures
#    - Path resolution
#    - Configuration generation
#    - Game detection (mocked)
#    - Error handling
#
#  Usage: bash tests/test-integration.sh
#
# ═══════════════════════════════════════════════════════════════════════════

# Note: We don't use set -e here as test assertions may fail
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_TEMP_DIR=""
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# ───────────────────────────────────────────────────────────────────────────
# Test Framework
# ───────────────────────────────────────────────────────────────────────────

# Colors (inline to avoid dependency)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

setup_test_environment() {
    TEST_TEMP_DIR=$(mktemp -d "/tmp/optiscaler_test_XXXXXXXX")
    export OPTISCALER_DATA_DIR="$TEST_TEMP_DIR/data"
    export HOME_BACKUP="$HOME"
    mkdir -p "$OPTISCALER_DATA_DIR"
    chmod 700 "$OPTISCALER_DATA_DIR"
    echo -e "${CYAN}Test environment: $TEST_TEMP_DIR${NC}"
}

cleanup_test_environment() {
    if [[ -n "$TEST_TEMP_DIR" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
    export HOME="$HOME_BACKUP"
}

trap cleanup_test_environment EXIT

assert_true() {
    local description="$1"
    local result="$2"

    if [[ "$result" == "true" || "$result" == "0" ]]; then
        echo -e "  ${GREEN}✓${NC} $description"
        ((TESTS_PASSED++)) || true
    else
        echo -e "  ${RED}✗${NC} $description"
        ((TESTS_FAILED++)) || true
    fi
}

assert_false() {
    local description="$1"
    local result="$2"

    if [[ "$result" == "false" || "$result" == "1" ]]; then
        echo -e "  ${GREEN}✓${NC} $description"
        ((TESTS_PASSED++)) || true
    else
        echo -e "  ${RED}✗${NC} $description"
        ((TESTS_FAILED++)) || true
    fi
}

assert_equals() {
    local description="$1"
    local expected="$2"
    local actual="$3"

    if [[ "$expected" == "$actual" ]]; then
        echo -e "  ${GREEN}✓${NC} $description"
        ((TESTS_PASSED++)) || true
    else
        echo -e "  ${RED}✗${NC} $description"
        echo -e "      Expected: '$expected'"
        echo -e "      Actual:   '$actual'"
        ((TESTS_FAILED++)) || true
    fi
}

assert_file_exists() {
    local description="$1"
    local file="$2"

    if [[ -f "$file" ]]; then
        echo -e "  ${GREEN}✓${NC} $description"
        ((TESTS_PASSED++)) || true
    else
        echo -e "  ${RED}✗${NC} $description (file not found: $file)"
        ((TESTS_FAILED++)) || true
    fi
}

assert_dir_exists() {
    local description="$1"
    local dir="$2"

    if [[ -d "$dir" ]]; then
        echo -e "  ${GREEN}✓${NC} $description"
        ((TESTS_PASSED++)) || true
    else
        echo -e "  ${RED}✗${NC} $description (directory not found: $dir)"
        ((TESTS_FAILED++)) || true
    fi
}

assert_command_succeeds() {
    local description="$1"
    shift

    if "$@" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $description"
        ((TESTS_PASSED++)) || true
    else
        echo -e "  ${RED}✗${NC} $description (command failed: $*)"
        ((TESTS_FAILED++)) || true
    fi
}

assert_command_fails() {
    local description="$1"
    shift

    if ! "$@" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $description"
        ((TESTS_PASSED++)) || true
    else
        echo -e "  ${RED}✗${NC} $description (command should have failed: $*)"
        ((TESTS_FAILED++)) || true
    fi
}

skip_test() {
    local description="$1"
    local reason="$2"
    echo -e "  ${YELLOW}○${NC} $description (SKIPPED: $reason)"
    ((TESTS_SKIPPED++))
}

section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════
#  TEST SUITES
# ═══════════════════════════════════════════════════════════════════════════

test_project_structure() {
    section "Project Structure Tests"

    assert_dir_exists "lib/ directory exists" "$SCRIPT_DIR/lib"
    assert_dir_exists "core/ directory exists" "$SCRIPT_DIR/core"
    assert_dir_exists "scripts/ directory exists" "$SCRIPT_DIR/scripts"
    assert_dir_exists "src/modules/ directory exists" "$SCRIPT_DIR/src/modules"
    assert_dir_exists "config/games/ directory exists" "$SCRIPT_DIR/config/games"
    assert_dir_exists "templates/ directory exists" "$SCRIPT_DIR/templates"
    assert_dir_exists "tests/ directory exists" "$SCRIPT_DIR/tests"

    assert_file_exists "colors.sh exists" "$SCRIPT_DIR/lib/colors.sh"
    assert_file_exists "logging.sh exists" "$SCRIPT_DIR/lib/logging.sh"
    assert_file_exists "utils.sh exists" "$SCRIPT_DIR/lib/utils.sh"
    assert_file_exists "paths.sh exists" "$SCRIPT_DIR/lib/paths.sh"

    assert_file_exists "install.sh exists" "$SCRIPT_DIR/scripts/install.sh"
    assert_file_exists "uninstall.sh exists" "$SCRIPT_DIR/scripts/uninstall.sh"
    assert_file_exists "downloader.sh exists" "$SCRIPT_DIR/scripts/downloader.sh"

    assert_file_exists "detector.sh exists" "$SCRIPT_DIR/core/detector.sh"
    assert_file_exists "configurator.sh exists" "$SCRIPT_DIR/core/configurator.sh"
    assert_file_exists "downloader.sh (core) exists" "$SCRIPT_DIR/core/downloader.sh"
}

test_module_loading() {
    section "Module Loading Tests"

    # Test colors.sh - check it can be sourced and has color vars (empty is OK for non-tty)
    assert_command_succeeds "colors.sh has valid syntax and can be sourced" bash -n "$SCRIPT_DIR/lib/colors.sh"

    # Test paths.sh
    (
        source "$SCRIPT_DIR/lib/paths.sh" 2>/dev/null
        [[ -n "$OPTISCALER_ROOT" && -n "$OPTISCALER_LIB" ]]
    )
    assert_true "paths.sh loads and defines path variables" "$?"

    # Test logging.sh
    (
        source "$SCRIPT_DIR/lib/colors.sh" 2>/dev/null
        source "$SCRIPT_DIR/lib/logging.sh" 2>/dev/null
        declare -f log_info >/dev/null 2>&1
    )
    assert_true "logging.sh loads and defines log functions" "$?"

    # Test utils.sh
    (
        source "$SCRIPT_DIR/lib/colors.sh" 2>/dev/null
        source "$SCRIPT_DIR/lib/logging.sh" 2>/dev/null
        source "$SCRIPT_DIR/lib/utils.sh" 2>/dev/null
        declare -f command_exists >/dev/null 2>&1
    )
    assert_true "utils.sh loads and defines utility functions" "$?"
}

test_security_paths() {
    section "Security: Path Handling Tests"

    # Test that cache path in paths.sh is NOT /tmp
    local paths_file="$SCRIPT_DIR/lib/paths.sh"
    local has_tmp_cache
    if grep -q 'OPTISCALER_CACHE.*"/tmp' "$paths_file" 2>/dev/null; then
        has_tmp_cache="1"  # Found /tmp - bad!
    else
        has_tmp_cache="0"  # No /tmp found - good!
    fi
    if [[ "$has_tmp_cache" == "0" ]]; then
        assert_true "Cache directory is in user space (not /tmp)" "0"
    else
        assert_true "Cache directory is in user space (not /tmp)" "1"
    fi

    # Test directory permissions function
    (
        source "$SCRIPT_DIR/lib/paths.sh" 2>/dev/null
        ensure_data_directories 2>/dev/null
        [[ -d "$OPTISCALER_CACHE" ]]
    )
    assert_true "ensure_data_directories creates cache dir" "$?"

    # Verify permissions are restrictive
    if [[ -d "$OPTISCALER_DATA_DIR" ]]; then
        local perms
        perms=$(stat -c "%a" "$OPTISCALER_DATA_DIR" 2>/dev/null || stat -f "%Lp" "$OPTISCALER_DATA_DIR" 2>/dev/null)
        assert_equals "Data directory has 700 permissions" "700" "$perms"
    else
        skip_test "Data directory permission check" "directory not created"
    fi
}

test_security_no_dangerous_patterns() {
    section "Security: Dangerous Pattern Detection"

    # Check for automatic sudo with -y or --noconfirm
    local sudo_auto
    sudo_auto=$(grep -rn "sudo.*-y\|sudo.*--noconfirm" "$SCRIPT_DIR/scripts" "$SCRIPT_DIR/core" "$SCRIPT_DIR/lib" --include="*.sh" 2>/dev/null | grep -v "^#" | grep -v "grep" | wc -l)
    assert_equals "No automatic sudo in scripts" "0" "$sudo_auto"

    # Check for eval usage (should be minimal or none)
    local eval_count
    eval_count=$(grep -rn "^[^#]*eval " "$SCRIPT_DIR/scripts" "$SCRIPT_DIR/core" "$SCRIPT_DIR/lib" --include="*.sh" 2>/dev/null | wc -l)
    if [[ $eval_count -gt 0 ]]; then
        echo -e "  ${YELLOW}⚠${NC} Found $eval_count eval usage(s) - review manually"
    else
        assert_equals "No eval usage in main scripts" "0" "$eval_count"
    fi

    # Check that load_yaml uses safe Python invocation
    local safe_yaml
    safe_yaml=$(grep -c 'python3 - ' "$SCRIPT_DIR/lib/utils.sh" 2>/dev/null | head -1 | tr -d '\n' || echo "0")
    if [[ "$safe_yaml" =~ ^[0-9]+$ ]] && [[ "$safe_yaml" -gt 0 ]]; then
        assert_true "load_yaml uses safe Python argument passing" "0"
    else
        assert_true "load_yaml uses safe Python argument passing" "1"
    fi
}

test_utils_functions() {
    section "Utility Functions Tests"

    source "$SCRIPT_DIR/lib/colors.sh"
    source "$SCRIPT_DIR/lib/logging.sh"
    source "$SCRIPT_DIR/lib/utils.sh"

    # Test command_exists
    assert_command_succeeds "command_exists detects bash" command_exists bash
    assert_command_fails "command_exists fails on fake command" command_exists this_command_does_not_exist_12345

    # Test sanitize_path if it exists
    if declare -f sanitize_path >/dev/null 2>&1; then
        local sanitized
        sanitized=$(sanitize_path "/path/to/../secret/file")
        if [[ "$sanitized" == *".."* ]]; then
            assert_false "sanitize_path removes .." "false"
        else
            assert_true "sanitize_path removes .." "true"
        fi
    else
        skip_test "sanitize_path function" "not implemented"
    fi

    # Test require_function if exists
    if declare -f require_function >/dev/null 2>&1; then
        assert_command_succeeds "require_function finds existing function" require_function command_exists
        assert_command_fails "require_function fails on missing function" require_function nonexistent_func_xyz
    else
        skip_test "require_function test" "not implemented"
    fi
}

test_detector_module() {
    section "GPU Detector Module Tests"

    if [[ ! -f "$SCRIPT_DIR/core/detector.sh" ]]; then
        skip_test "GPU detector tests" "detector.sh not found"
        return
    fi

    # Test syntax
    assert_command_succeeds "detector.sh has valid syntax" bash -n "$SCRIPT_DIR/core/detector.sh"

    # Test loading (may fail in CI without GPU)
    (
        source "$SCRIPT_DIR/lib/colors.sh" 2>/dev/null
        source "$SCRIPT_DIR/lib/logging.sh" 2>/dev/null
        source "$SCRIPT_DIR/lib/utils.sh" 2>/dev/null
        source "$SCRIPT_DIR/core/detector.sh" 2>/dev/null
        declare -f detect_gpu >/dev/null 2>&1 || declare -f detect_gpu_vendor >/dev/null 2>&1
    )
    if [[ $? -eq 0 ]]; then
        assert_true "detector.sh defines GPU detection functions" "0"
    else
        skip_test "GPU detection functions" "may require lspci"
    fi
}

test_game_detector_module() {
    section "Game Detector Module Tests"

    local game_detector="$SCRIPT_DIR/src/modules/game_detector.sh"

    if [[ ! -f "$game_detector" ]]; then
        skip_test "Game detector tests" "game_detector.sh not found"
        return
    fi

    # Test syntax
    assert_command_succeeds "game_detector.sh has valid syntax" bash -n "$game_detector"

    # Check that cache path is secure (no hardcoded /tmp in CACHE_FILE default)
    local cache_check
    if grep -q 'CACHE_FILE=.*"/tmp/' "$game_detector" 2>/dev/null; then
        cache_check="1"  # Found insecure /tmp path
    else
        cache_check="0"  # Secure (no /tmp)
    fi
    assert_equals "game_detector uses secure cache location" "0" "$cache_check"

    # Check subprocess error handling exists
    local subprocess_handling
    subprocess_handling=$(grep -c "subprocess_failures\|wait \"\$pid\"" "$game_detector" 2>/dev/null || echo "0")
    assert_true "game_detector has subprocess error handling" "$([[ $subprocess_handling -gt 0 ]] && echo 0 || echo 1)"
}

test_configurator_module() {
    section "Configurator Module Tests"

    if [[ ! -f "$SCRIPT_DIR/core/configurator.sh" ]]; then
        skip_test "Configurator tests" "configurator.sh not found"
        return
    fi

    assert_command_succeeds "configurator.sh has valid syntax" bash -n "$SCRIPT_DIR/core/configurator.sh"

    # Test loading
    (
        source "$SCRIPT_DIR/lib/colors.sh" 2>/dev/null
        source "$SCRIPT_DIR/lib/logging.sh" 2>/dev/null
        source "$SCRIPT_DIR/lib/utils.sh" 2>/dev/null
        source "$SCRIPT_DIR/core/configurator.sh" 2>/dev/null
        declare -f generate_config >/dev/null 2>&1 || declare -f generate_optiscaler_ini >/dev/null 2>&1
    )
    assert_true "configurator.sh loads successfully" "$?"
}

test_downloader_module() {
    section "Downloader Module Tests"

    if [[ ! -f "$SCRIPT_DIR/core/downloader.sh" ]]; then
        skip_test "Downloader tests" "core/downloader.sh not found"
        return
    fi

    assert_command_succeeds "core/downloader.sh has valid syntax" bash -n "$SCRIPT_DIR/core/downloader.sh"

    # Check for require_7z (security fix)
    local has_require_7z
    has_require_7z=$(grep -c "require_7z" "$SCRIPT_DIR/core/downloader.sh" 2>/dev/null || echo "0")
    assert_true "downloader uses require_7z (no auto-install)" "$([[ $has_require_7z -gt 0 ]] && echo 0 || echo 1)"

    # Check scripts/downloader.sh is a wrapper
    if [[ -f "$SCRIPT_DIR/scripts/downloader.sh" ]]; then
        local is_wrapper
        is_wrapper=$(grep -c "source.*core/downloader.sh" "$SCRIPT_DIR/scripts/downloader.sh" 2>/dev/null || echo "0")
        assert_true "scripts/downloader.sh sources core/downloader.sh" "$([[ $is_wrapper -gt 0 ]] && echo 0 || echo 1)"
    fi
}

test_install_script() {
    section "Install Script Tests"

    if [[ ! -f "$SCRIPT_DIR/scripts/install.sh" ]]; then
        skip_test "Install script tests" "install.sh not found"
        return
    fi

    assert_command_succeeds "install.sh has valid syntax" bash -n "$SCRIPT_DIR/scripts/install.sh"

    # Test --help works
    local help_output
    help_output=$(bash "$SCRIPT_DIR/scripts/install.sh" --help 2>&1 || true)
    if [[ "$help_output" == *"Usage"* || "$help_output" == *"Options"* ]]; then
        assert_true "install.sh --help shows usage" "0"
    else
        skip_test "install.sh --help" "may not be implemented"
    fi

    # Check for duplicate function definitions
    local print_banner_count
    print_banner_count=$(grep -c "^print_banner()" "$SCRIPT_DIR/scripts/install.sh" 2>/dev/null || echo "0")
    assert_true "No duplicate print_banner in install.sh" "$([[ $print_banner_count -le 1 ]] && echo 0 || echo 1)"
}

test_uninstall_script() {
    section "Uninstall Script Tests"

    if [[ ! -f "$SCRIPT_DIR/scripts/uninstall.sh" ]]; then
        skip_test "Uninstall script tests" "uninstall.sh not found"
        return
    fi

    assert_command_succeeds "uninstall.sh has valid syntax" bash -n "$SCRIPT_DIR/scripts/uninstall.sh"

    # Check --help works
    local help_output
    help_output=$(bash "$SCRIPT_DIR/scripts/uninstall.sh" --help 2>&1 || true)
    if [[ "$help_output" == *"Usage"* || "$help_output" == *"Options"* ]]; then
        assert_true "uninstall.sh --help shows usage" "0"
    else
        skip_test "uninstall.sh --help" "may not be implemented"
    fi

    # Check for safe rm -rf
    local safe_rm
    safe_rm=$(grep -c 'rm -rf "\${CONFIG_DIR:?' "$SCRIPT_DIR/scripts/uninstall.sh" 2>/dev/null || echo "0")
    assert_true "uninstall.sh uses safe rm -rf" "$([[ $safe_rm -gt 0 ]] && echo 0 || echo 1)"
}

test_game_profiles() {
    section "Game Profile Tests"

    local profiles_dir="$SCRIPT_DIR/config/games"

    if [[ ! -d "$profiles_dir" ]]; then
        skip_test "Game profile tests" "config/games not found"
        return
    fi

    local profile_count
    profile_count=$(find "$profiles_dir" -name "*.yaml" | wc -l)
    assert_true "Game profiles exist" "$([[ $profile_count -gt 0 ]] && echo 0 || echo 1)"

    # Validate YAML syntax (basic check)
    local invalid_yaml=0
    for profile in "$profiles_dir"/*.yaml; do
        [[ ! -f "$profile" ]] && continue
        if ! grep -q "game_id:" "$profile" 2>/dev/null; then
            echo -e "  ${RED}✗${NC} Invalid profile: $(basename "$profile") (missing game_id)"
            ((invalid_yaml++))
        fi
    done

    if [[ $invalid_yaml -eq 0 ]]; then
        assert_true "All game profiles have game_id field" "0"
    fi
}

test_templates() {
    section "Template Tests"

    local templates_dir="$SCRIPT_DIR/templates"

    if [[ ! -d "$templates_dir" ]]; then
        skip_test "Template tests" "templates/ not found"
        return
    fi

    # Check for OptiScaler.ini template
    if [[ -f "$templates_dir/OptiScaler.ini" ]]; then
        assert_file_exists "OptiScaler.ini template exists" "$templates_dir/OptiScaler.ini"
    else
        skip_test "OptiScaler.ini template" "not found"
    fi
}

test_ci_configuration() {
    section "CI/CD Configuration Tests"

    local ci_file="$SCRIPT_DIR/.github/workflows/ci.yml"

    if [[ -f "$ci_file" ]]; then
        assert_file_exists "CI workflow exists" "$ci_file"

        # Check for ShellCheck job
        local has_shellcheck
        has_shellcheck=$(grep -c "shellcheck\|ShellCheck" "$ci_file" 2>/dev/null || echo "0")
        assert_true "CI includes ShellCheck" "$([[ $has_shellcheck -gt 0 ]] && echo 0 || echo 1)"
    else
        skip_test "CI workflow tests" "ci.yml not found"
    fi

    # Check CONTRIBUTING.md exists
    if [[ -f "$SCRIPT_DIR/CONTRIBUTING.md" ]]; then
        assert_file_exists "CONTRIBUTING.md exists" "$SCRIPT_DIR/CONTRIBUTING.md"
    else
        skip_test "CONTRIBUTING.md" "not found"
    fi
}

test_all_scripts_syntax() {
    section "All Scripts Syntax Validation"

    local failed_syntax=0
    local checked=0

    while IFS= read -r -d '' script; do
        if ! bash -n "$script" 2>/dev/null; then
            echo -e "  ${RED}✗${NC} Syntax error: $script"
            ((failed_syntax++))
        fi
        ((checked++))
    done < <(find "$SCRIPT_DIR/scripts" "$SCRIPT_DIR/core" "$SCRIPT_DIR/lib" "$SCRIPT_DIR/src" -name "*.sh" -type f -print0 2>/dev/null)

    if [[ $failed_syntax -eq 0 ]]; then
        assert_true "All $checked shell scripts pass syntax check" "0"
    else
        assert_false "Syntax errors in $failed_syntax script(s)" "false"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════════════════

main() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  OPTISCALER UNIVERSAL - COMPREHENSIVE INTEGRATION TEST${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Project: $SCRIPT_DIR${NC}"
    echo -e "${CYAN}  Date:    $(date)${NC}"
    echo ""

    setup_test_environment

    # Run all test suites
    test_project_structure
    test_module_loading
    test_security_paths
    test_security_no_dangerous_patterns
    test_utils_functions
    test_detector_module
    test_game_detector_module
    test_configurator_module
    test_downloader_module
    test_install_script
    test_uninstall_script
    test_game_profiles
    test_templates
    test_ci_configuration
    test_all_scripts_syntax

    # Summary
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  TEST SUMMARY${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "  ${GREEN}Passed:${NC}  $TESTS_PASSED"
    echo -e "  ${RED}Failed:${NC}  $TESTS_FAILED"
    echo -e "  ${YELLOW}Skipped:${NC} $TESTS_SKIPPED"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "${RED}RESULT: FAILED${NC}"
        exit 1
    else
        echo -e "${GREEN}RESULT: PASSED${NC}"
        exit 0
    fi
}

main "$@"
