# Contributing to OptiScaler Universal

Thank you for your interest in contributing to OptiScaler Universal! This document provides guidelines and best practices for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Code Style Guidelines](#code-style-guidelines)
- [Security Guidelines](#security-guidelines)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

Be respectful, inclusive, and constructive. We welcome contributors of all experience levels.

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/0ptiscaler4linux.git
   cd 0ptiscaler4linux
   ```
3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/ind4skylivey/0ptiscaler4linux.git
   ```

## Development Setup

### Prerequisites

- Bash 4.0+
- ShellCheck (for linting)
- Python 3 (for YAML parsing)
- Common Linux utilities: `lspci`, `wget`, `curl`, `unzip`, `tar`

### Install Development Tools

```bash
# Arch Linux
sudo pacman -S shellcheck bash-completion python-yaml

# Ubuntu/Debian
sudo apt install shellcheck bash-completion python3-yaml

# Fedora
sudo dnf install ShellCheck bash-completion python3-pyyaml
```

### Running Locally

```bash
# Run the installer in scan-only mode
bash scripts/install.sh --scan-only --debug

# Run tests
bash tests/run-all-tests.sh

# Run ShellCheck on all scripts
shellcheck scripts/*.sh core/*.sh lib/*.sh src/modules/*.sh
```

## Code Style Guidelines

### Variable Naming

```bash
# UPPERCASE: Environment variables and global constants
readonly VERSION="1.0.0"
export OPTISCALER_ROOT="/path/to/project"

# lowercase_snake_case: Local variables
local game_path=""
local app_id=""

# Avoid: CamelCase, hungarian notation
```

### Quoting

**Always quote variable expansions** to prevent word splitting:

```bash
# ✅ Correct
echo "$variable"
if [[ -f "$file_path" ]]; then

# ❌ Wrong
echo $variable
if [ -f $file_path ]; then
```

### Arrays

```bash
# ✅ Correct array iteration
for item in "${array[@]}"; do

# ❌ Wrong
for item in ${array[@]}; do
```

### Functions

```bash
# ───────────────────────────────────────────────────────────────────────────
# function_name - Brief description
#
# Arguments:
#   $1 - arg_name: Description
#   $2 - (Optional) another_arg: Description
#
# Returns:
#   0 on success, 1 on failure
#   Outputs result to stdout
#
# Side effects:
#   - Modifies GLOBAL_VAR
#   - Creates files in /tmp
# ───────────────────────────────────────────────────────────────────────────
function_name() {
    local arg_name="$1"
    local another_arg="${2:-default_value}"

    # Implementation
}
```

### Error Handling

```bash
# Use set -eo pipefail at script start
set -eo pipefail

# Check command success explicitly
if ! some_command; then
    log_error "Command failed"
    return 1
fi

# Use || true for commands that may fail non-fatally
((counter++)) || true
```

## Security Guidelines

### CRITICAL: Never Do These

1. **No automatic sudo**: Never run `sudo` without explicit user consent

   ```bash
   # ❌ NEVER
   sudo pacman -S package --noconfirm

   # ✅ Instead, inform the user
   log_error "Package X required. Install with: sudo pacman -S package"
   return 1
   ```

2. **No string interpolation in commands**:

   ```bash
   # ❌ VULNERABLE to command injection
   python3 -c "with open('$user_file') as f: ..."

   # ✅ Pass as argument
   python3 - "$user_file" << 'SCRIPT'
   import sys
   with open(sys.argv[1]) as f: ...
   SCRIPT
   ```

3. **No /tmp for sensitive data**:

   ```bash
   # ❌ World-readable, symlink attacks possible
   CACHE="/tmp/myapp_cache"

   # ✅ Use user directory with restricted permissions
   CACHE="$HOME/.myapp/cache"
   mkdir -p "$CACHE"
   chmod 700 "$CACHE"
   ```

4. **No eval**:

   ```bash
   # ❌ NEVER
   eval "$user_input"

   # ✅ Use proper argument handling instead
   ```

### Secure File Operations

```bash
# Create secure temporary files
tmp=$(mktemp -p "$SECURE_DIR" "prefix_XXXXXXXX.tmp")

# Restrict directory permissions
mkdir -p "$dir"
chmod 700 "$dir"

# Validate paths
if [[ "$path" == *".."* ]]; then
    log_error "Path traversal detected"
    return 1
fi
```

### Input Validation

```bash
# Validate arguments
if [[ -z "$arg" ]]; then
    log_error "Argument required"
    return 1
fi

# Validate CLI options
case "$1" in
    --known-option) ;;
    --*) log_error "Unknown option: $1"; exit 1 ;;
esac
```

## Testing

### Running Tests

```bash
# Run all tests
bash tests/run-all-tests.sh

# Run specific test
bash tests/test-detector.sh

# Run with verbose output
DEBUG_MODE=true bash tests/run-all-tests.sh
```

### Writing Tests

Create test files in `tests/test-*.sh`:

```bash
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/logging.sh"

TESTS_PASSED=0
TESTS_FAILED=0

# Test helper
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"

    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓${NC} $message"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} $message"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        ((TESTS_FAILED++))
    fi
}

# Test cases
test_my_function() {
    local result=$(my_function "input")
    assert_equals "expected_output" "$result" "my_function returns correct value"
}

# Run tests
test_my_function

# Report
echo ""
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
[[ $TESTS_FAILED -eq 0 ]]
```

## Pull Request Process

### Before Submitting

1. **Run ShellCheck**:

   ```bash
   shellcheck scripts/*.sh core/*.sh lib/*.sh src/modules/*.sh
   ```

2. **Run tests**:

   ```bash
   bash tests/run-all-tests.sh
   ```

3. **Test manually**:

   ```bash
   bash scripts/install.sh --scan-only
   ```

4. **Check for security issues**:

   ```bash
   # No automatic sudo
   grep -rn "sudo.*-y\|sudo.*--noconfirm" scripts/ core/ lib/

   # No eval
   grep -rn "eval " scripts/ core/ lib/

   # No /tmp hardcoding
   grep -rn '"/tmp/' scripts/ core/ lib/
   ```

### PR Checklist

- [ ] Code follows style guidelines
- [ ] All functions are documented
- [ ] No security anti-patterns
- [ ] ShellCheck passes with no errors
- [ ] Tests pass
- [ ] New features have tests
- [ ] CHANGELOG updated (if applicable)

### Commit Messages

Follow conventional commits:

```
type(scope): short description

Longer description if needed.

Fixes #123
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `security`

Examples:

```
feat(detector): add support for GOG games
fix(security): use mktemp in user directory
docs: update installation instructions
security: remove automatic sudo execution
```

## Questions?

Open an issue or start a discussion. We're happy to help!
