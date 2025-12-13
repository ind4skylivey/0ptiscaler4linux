#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - DEPENDENCY DOWNLOADER (COMPATIBILITY WRAPPER)
# ═══════════════════════════════════════════════════════════════════════════
#
#  This file exists for backwards compatibility.
#  All functionality is now in core/downloader.sh
#
#  DO NOT add new code here - modify core/downloader.sh instead.
#
# ═══════════════════════════════════════════════════════════════════════════

# Resolve script directory
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Source the authoritative implementation
if [[ -f "$SCRIPT_DIR/core/downloader.sh" ]]; then
    source "$SCRIPT_DIR/core/downloader.sh"
else
    echo "ERROR: core/downloader.sh not found" >&2
    exit 1
fi
