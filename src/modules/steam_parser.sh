#!/bin/bash

# =============================================================================
#  OPTISCALER UNIVERSAL - STEAM VDF PARSER
# =============================================================================
#  Lightweight, dependency-free parser for Steam VDF/ACF files.
#  It flattens nested keys into dot notation suitable for associative arrays.
# =============================================================================

# parse_vdf <file> <out_assoc_name>
#   Parses a VDF/ACF file into the supplied associative array (passed by name).
#   Keys are flattened using dot notation: libraryfolders.0.path
#   Returns 0 on success, 1 on missing file.
parse_vdf() {
    local file="$1"
    local out_name="$2"

    if [[ -z "$file" || -z "$out_name" ]]; then
        echo "parse_vdf: missing arguments" >&2
        return 1
    fi

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    # shellcheck disable=SC2178
    declare -n __out="$out_name"
    __out=()

    local -a stack=()
    while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
        # Strip comments and trim
        local line="$raw_line"
        line="${line%%#*}"
        line="${line%%//*}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -z "$line" ]] && continue

        # Handle block end
        if [[ "$line" == "}" ]]; then
            [[ ${#stack[@]} -gt 0 ]] && unset 'stack[-1]'
            continue
        fi

        # Handle block start: "key"
        if [[ "$line" =~ ^\"([^\"]+)\"[[:space:]]*\{$ ]]; then
            stack+=("${BASH_REMATCH[1]}")
            continue
        fi

        # Handle key-value: "key"  "value"
        if [[ "$line" =~ ^\"([^\"]+)\"[[:space:]]*\"(.*)\"$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local val="${BASH_REMATCH[2]}"

            local full_key
            if [[ ${#stack[@]} -gt 0 ]]; then
                full_key="$(IFS=.; echo "${stack[*]}").$key"
            else
                full_key="$key"
            fi

            __out["$full_key"]="$val"
        fi
    done < "$file"

    return 0
}

# parse_appmanifest <file> <out_assoc_name>
#   Convenience wrapper that returns normalized keys:
#     appid, name, installdir, stateflags, installdir_path (optional)
parse_appmanifest() {
    local file="$1"
    local out_name="$2"

    declare -A vdf=()
    parse_vdf "$file" vdf || return 1

    # shellcheck disable=SC2178
    declare -n __out="$out_name"
    __out=()
    __out[appid]="${vdf[AppState.appid]:-}"
    __out[name]="${vdf[AppState.name]:-}"
    __out[installdir]="${vdf[AppState.installdir]:-}"
    __out[stateflags]="${vdf[AppState.StateFlags]:-}"
    __out[sharedinstall]="${vdf[AppState.SharedInstall]:-}"
    __out[staged]="${vdf[AppState.Staged]:-}"

    return 0
}

# parse_libraryfolders <file> <out_array_name>
#   Extracts library paths from libraryfolders.vdf into provided array (by name).
parse_libraryfolders() {
    local file="$1"
    local out_name="$2"

    declare -A vdf=()
    parse_vdf "$file" vdf || return 1

    # shellcheck disable=SC2178
    declare -n __out="$out_name"
    __out=()

    for key in "${!vdf[@]}"; do
        if [[ "$key" =~ ^libraryfolders\.[0-9]+\.path$ ]]; then
            local path="${vdf[$key]}"
            # Normalise to library root (without trailing slash)
            path="${path%/}"
            __out+=("$path")
        fi
    done

    return 0
}

export -f parse_vdf
export -f parse_appmanifest
export -f parse_libraryfolders
