#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - UTILITIES LIBRARY
# ═══════════════════════════════════════════════════════════════════════════

# Load YAML file
load_yaml() {
    local yaml_file="$1"
    
    if [ ! -f "$yaml_file" ]; then
        log_error "YAML file not found: $yaml_file"
        return 1
    fi
    
    # Simple YAML parser (requires python or yq)
    if command -v python3 &> /dev/null; then
        python3 -c "
import yaml, json, sys
with open('$yaml_file') as f:
    print(json.dumps(yaml.safe_load(f)))
"
    else
        log_warn "Python3 not found, YAML parsing limited"
        return 1
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Get file size in human readable format
get_file_size() {
    local file="$1"
    if [ -f "$file" ]; then
        du -h "$file" | cut -f1
    else
        echo "0B"
    fi
}

# Create backup
create_backup() {
    local source="$1"
    local backup_dir="${2:-$HOME/.optiscaler-universal/backups}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$backup_dir"
    
    if [ -f "$source" ]; then
        cp "$source" "$backup_dir/$(basename "$source").$timestamp"
        log_info "Backed up: $source"
    elif [ -d "$source" ]; then
        cp -r "$source" "$backup_dir/$(basename "$source").$timestamp"
        log_info "Backed up: $source"
    fi
}

# Verify checksum
verify_checksum() {
    local file="$1"
    local expected_hash="$2"
    local actual_hash=$(sha256sum "$file" | cut -d' ' -f1)
    
    if [ "$expected_hash" = "$actual_hash" ]; then
        return 0
    else
        log_error "Checksum mismatch for $file"
        log_error "Expected: $expected_hash"
        log_error "Got: $actual_hash"
        return 1
    fi
}

# Prompt yes/no
prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    
    while true; do
        if [ "$default" = "y" ]; then
            read -p "$prompt [Y/n]: " -n 1 -r
        else
            read -p "$prompt [y/N]: " -n 1 -r
        fi
        echo
        
        if [[ -z "$REPLY" ]]; then
            REPLY="$default"
        fi
        
        case "$REPLY" in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Export functions
export -f load_yaml
export -f command_exists
export -f get_file_size
export -f create_backup
export -f verify_checksum
export -f prompt_yes_no
