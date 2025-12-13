#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - STEAM GAME DETECTOR (MULTI-DISK, SECURITY HARDENED)
# ═══════════════════════════════════════════════════════════════════════════
#
#  Implements cascading detection methods for Steam games across any mounted
#  disk/partition, with caching and structured output for downstream modules.
#
#  Security improvements:
#    - Cache stored in user directory (not /tmp)
#    - Proper permissions on cache directory
#    - Safe temporary file handling
#    - Input validation on paths
#
# ═══════════════════════════════════════════════════════════════════════════

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

SCRIPT_ROOT="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
PROFILES_DIR="${PROFILES_DIR:-$SCRIPT_ROOT/config/games}"

# SECURITY: Use user-owned directory for cache (not world-writable /tmp)
OPTISCALER_DATA_DIR="${OPTISCALER_DATA_DIR:-$HOME/.optiscaler-universal}"
CACHE_DIR="$OPTISCALER_DATA_DIR/cache"
CACHE_FILE="${CACHE_FILE:-$CACHE_DIR/scan_cache.dat}"

# Ensure cache directory exists with proper permissions
if [[ ! -d "$CACHE_DIR" ]]; then
    mkdir -p "$CACHE_DIR" 2>/dev/null || true
    chmod 700 "$CACHE_DIR" 2>/dev/null || true
fi

readonly CACHE_TTL_SECONDS=300  # 5 minutes
DELIM=${DELIM:-$'\x1f'}  # record delimiter safe for paths containing ';'

# -----------------------------------------------------------------------------
# Global data structures
# -----------------------------------------------------------------------------

declare -A PROFILE_PATH               # game_id -> yaml path
declare -A PROFILE_APPID              # game_id -> app id
declare -A PROFILE_NAME               # game_id -> display name
declare -A PROFILE_FOLDER_PATTERNS    # game_id -> semicolon list
declare -A PROFILE_EXECUTABLES        # game_id -> semicolon list
declare -A PROFILE_REQUIRED_FILES     # game_id -> semicolon list
declare -A PROFILE_DLL_TARGETS        # game_id -> semicolon list
declare -A PROFILE_BY_APPID           # appid -> game_id

declare -a STEAM_LIBRARIES=()         # list of steamapps roots
declare -a DETECTED_GAMES=()          # supported (with profile) entries
declare -A DETECTED_BY_APPID=()       # supported appid -> index mapping
declare -a DETECTED_UNSUPPORTED=()    # without profile entries
declare -A MANIFEST_BY_DIR=()         # installdir(lower) -> "appid|name|stateflags"

VERBOSE_MODE="${VERBOSE_MODE:-false}"
DEBUG_MODE="${DEBUG_MODE:-false}"
FORCE_RESCAN="${FORCE_RESCAN:-false}"
CURRENT_USER="${USER:-$(whoami 2>/dev/null || echo unknown)}"

# -----------------------------------------------------------------------------
# Helpers: parsing profile YAML (lightweight, structure-limited)
# -----------------------------------------------------------------------------

_yaml_value() {
    local line="$1"
    line="${line#\"}"
    line="${line%\"}"
    echo "$line"
}

load_detection_profiles() {
    # Ensure globals are associative even if sourced multiple times
    declare -gA PROFILE_PATH PROFILE_APPID PROFILE_NAME PROFILE_FOLDER_PATTERNS PROFILE_EXECUTABLES PROFILE_REQUIRED_FILES PROFILE_DLL_TARGETS PROFILE_BY_APPID MANIFEST_BY_DIR

    if [[ ! -d "$PROFILES_DIR" ]]; then
        log_error "Game profiles directory not found: $PROFILES_DIR"
        return 1
    fi

    local profile_file
    for profile_file in "$PROFILES_DIR"/*.yaml; do
        [[ ! -f "$profile_file" ]] && continue

        local game_id name app_id
        local -a folders=() executables=() required=() dll_targets=()
        local mode=""

        while IFS= read -r raw || [[ -n "$raw" ]]; do
            # trim leading spaces
            local line="${raw#"${raw%%[![:space:]]*}"}"
            [[ "$line" =~ ^# ]] && continue
            [[ -z "$line" ]] && continue

            if [[ "$line" =~ ^game_id: ]]; then
                game_id=$(_yaml_value "${line#game_id: }")
            elif [[ "$line" =~ ^name: ]]; then
                name=$(_yaml_value "${line#name: }")
            elif [[ "$line" =~ ^app_id: ]]; then
                app_id=$(_yaml_value "${line#app_id: }")
            elif [[ "$line" =~ ^folder_patterns: ]]; then
                mode="folder"
            elif [[ "$line" =~ ^executables: ]]; then
                mode="exe"
            elif [[ "$line" =~ ^required_files: ]]; then
                mode="req"
            elif [[ "$line" =~ ^dll_targets: ]]; then
                mode="dll"
            elif [[ "$line" =~ ^- ]]; then
                local value=$(_yaml_value "${line#- }")
                case "$mode" in
                    folder) folders+=("$value") ;;
                    exe) executables+=("$value") ;;
                    req) required+=("$value") ;;
                    dll) dll_targets+=("$value") ;;
                esac
            fi
        done < "$profile_file"

        if [[ -z "$game_id" || -z "$app_id" ]]; then
            log_debug "Skipping profile $(basename "$profile_file") (game_id='$game_id', app_id='$app_id')"
            continue
        fi

        log_debug "Profile loaded: $(basename "$profile_file") -> game_id='$game_id' app_id='$app_id'"

        PROFILE_PATH["$game_id"]="$profile_file"
        PROFILE_APPID["$game_id"]="$app_id"
        PROFILE_NAME["$game_id"]="$name"
        PROFILE_FOLDER_PATTERNS["$game_id"]="$(IFS=';'; echo "${folders[*]}")"
        PROFILE_EXECUTABLES["$game_id"]="$(IFS=';'; echo "${executables[*]}")"
        PROFILE_REQUIRED_FILES["$game_id"]="$(IFS=';'; echo "${required[*]}")"
        PROFILE_DLL_TARGETS["$game_id"]="$(IFS=';'; echo "${dll_targets[*]}")"
        PROFILE_BY_APPID["$app_id"]="$game_id"
    done

    log_debug "Loaded ${#PROFILE_PATH[@]} game detection profiles from $PROFILES_DIR"
    return 0
}

list_supported_games() {
    for gid in "${!PROFILE_PATH[@]}"; do
        local name="${PROFILE_NAME[$gid]:-$gid}"
        local appid="${PROFILE_APPID[$gid]}"
        echo " - $name (AppID: $appid, id: $gid)"
    done | sort
}

# -----------------------------------------------------------------------------
# Steam library discovery
# -----------------------------------------------------------------------------

_add_library_if_exists() {
    local path="$1"
    [[ -z "$path" ]] && return
    path="${path%/}"
    [[ -d "$path/steamapps" ]] || return
    for existing in "${STEAM_LIBRARIES[@]}"; do
        [[ "$existing" == "$path/steamapps" ]] && return
    done
    STEAM_LIBRARIES+=("$path/steamapps")
    log_debug "Library registered: $path/steamapps"
}

discover_libraryfolders_files() {
    local -a files=()
    local candidates=(
        "$HOME/.steam/steam/steamapps/libraryfolders.vdf"
        "$HOME/.local/share/Steam/steamapps/libraryfolders.vdf"
        "$HOME/.steam/steam/config/libraryfolders.vdf"
        "$HOME/.local/share/Steam/config/libraryfolders.vdf"
    )

    # user-provided hints
    IFS=':' read -r -a hint_paths <<< "${OPTISCALER_STEAM_HINTS:-}"
    for hint in "${hint_paths[@]}"; do
        [[ -z "$hint" ]] && continue
        candidates+=("$hint/steamapps/libraryfolders.vdf" "$hint/libraryfolders.vdf")
    done

    for cand in "${candidates[@]}"; do
        [[ -f "$cand" ]] && files+=("$cand")
    done

    # Walk common mount points
    for root in /mnt /media "/run/media/$CURRENT_USER"; do
        [[ -d "$root" ]] || continue
        while IFS= read -r -d '' lf; do
            files+=("$lf")
        done < <(find "$root" -maxdepth 5 -type f -name "libraryfolders.vdf" -print0 2>/dev/null)
    done

    # Remove duplicates
    printf "%s\n" "${files[@]}" | sort -u
}

discover_steam_libraries() {
    local skip_defaults="${OPTISCALER_SKIP_DEFAULTS:-false}"
    STEAM_LIBRARIES=()

    # Always include defaults if they exist
    if [[ "$skip_defaults" != "true" ]]; then
        _add_library_if_exists "$HOME/.steam/steam"
        _add_library_if_exists "$HOME/.local/share/Steam"
    fi

    # Hint paths are always added explicitly
    IFS=':' read -r -a hint_paths <<< "${OPTISCALER_STEAM_HINTS:-}"
    for hint in "${hint_paths[@]}"; do
        _add_library_if_exists "$hint"
    done

    local lf
    while IFS= read -r lf; do
        declare -a libs=()
        parse_libraryfolders "$lf" libs || continue
        for lib_root in "${libs[@]}"; do
            _add_library_if_exists "$lib_root"
        done
    done < <(discover_libraryfolders_files)

    # Last-resort scan for steamapps directories
    for root in /mnt /media "/run/media/$CURRENT_USER"; do
        [[ -d "$root" ]] || continue
        while IFS= read -r -d '' sa; do
            local base="${sa%/steamapps}"
            _add_library_if_exists "$base"
        done < <(find "$root" -maxdepth 5 -type d -name "steamapps" -print0 2>/dev/null)
    done

    log_info "Found ${#STEAM_LIBRARIES[@]} Steam library(ies)"
    return 0
}

# -----------------------------------------------------------------------------
# Validation helpers
# -----------------------------------------------------------------------------

_is_writable() {
    local path="$1"
    [[ -w "$path" ]] && return 0
    touch "$path/.optiscaler_write_test" 2>/dev/null && rm -f "$path/.optiscaler_write_test" && return 0
    return 1
}

_first_existing_subdir() {
    local base="$1"
    shift
    for sub in "$@"; do
        [[ -d "$base/$sub" ]] && { echo "$base/$sub"; return 0; }
    done
    echo ""
}

validate_installation() {
    local game_id="$1"
    local app_id="$2"
    local install_path="$3"
    local detection_method="$4"

    [[ -z "$install_path" ]] && return 1
    [[ ! -d "$install_path" ]] && { log_debug "Missing install path $install_path"; return 1; }

    local req="${PROFILE_REQUIRED_FILES[$game_id]}"
    IFS=';' read -r -a req_list <<< "$req"
    for f in "${req_list[@]}"; do
        [[ -z "$f" ]] && continue
        [[ -e "$install_path/$f" ]] || { log_debug "Missing required file $f for $game_id"; return 1; }
    done

    local dll_dir=""
    IFS=';' read -r -a dlls <<< "${PROFILE_DLL_TARGETS[$game_id]}"
    dll_dir="$(_first_existing_subdir "$install_path" "${dlls[@]}")"

    local writable="false"
    if _is_writable "$install_path"; then
        writable="true"
    fi

    local proton_prefix=""
    local is_proton="false"
    local steamapps_base="${install_path%/common/*}/compatdata"
    if [[ -d "$steamapps_base/$app_id/pfx" ]]; then
        proton_prefix="$steamapps_base/$app_id/pfx"
        is_proton="true"
    fi

    local profile_path="${PROFILE_PATH[$game_id]}"
    local game_name="${PROFILE_NAME[$game_id]:-$game_id}"

    local record="game_id=$game_id${DELIM}game_name=$game_name${DELIM}app_id=$app_id${DELIM}install_path=$install_path${DELIM}dll_target_dir=$dll_dir${DELIM}detection_method=$detection_method${DELIM}is_proton=$is_proton${DELIM}proton_prefix=$proton_prefix${DELIM}writable=$writable${DELIM}profile_matched=$profile_path"

    DETECTED_BY_APPID["$app_id"]="${#DETECTED_GAMES[@]}"
    DETECTED_GAMES+=("$record")
    log_success "Detected: $game_name (AppID: $app_id) via $detection_method"
    return 0
}

record_unsupported() {
    local app_id="$1"
    local name="$2"
    local install_path="$3"
    local detection_method="$4"

    local writable="false"
    _is_writable "$install_path" && writable="true"

    local proton_prefix=""
    local is_proton="false"
    local steamapps_base="${install_path%/common/*}/compatdata"
    if [[ -d "$steamapps_base/$app_id/pfx" ]]; then
        proton_prefix="$steamapps_base/$app_id/pfx"
        is_proton="true"
    fi

    local record="game_name=$name${DELIM}app_id=$app_id${DELIM}install_path=$install_path${DELIM}detection_method=$detection_method${DELIM}is_proton=$is_proton${DELIM}proton_prefix=$proton_prefix${DELIM}writable=$writable${DELIM}profile_matched="
    DETECTED_UNSUPPORTED+=("$record")
    log_info "Detected (no profile): $name (AppID: $app_id) via $detection_method"
}

# -----------------------------------------------------------------------------
# Detection methods
# -----------------------------------------------------------------------------

_match_profile_by_appid() {
    local app_id="$1"
    local gid="${PROFILE_BY_APPID[$app_id]}"
    [[ -n "$gid" ]] && echo "$gid"
    return 0
}

_match_profile_by_folder() {
    local folder_name="$1"
    local folder_lower="${folder_name,,}"
    local folder_compact="${folder_lower// /}"
    local gid patterns
    for gid in "${!PROFILE_PATH[@]}"; do
        IFS=';' read -r -a patterns <<< "${PROFILE_FOLDER_PATTERNS[$gid]}"
        for pat in "${patterns[@]}"; do
            [[ -z "$pat" ]] && continue
            local pat_lower="${pat,,}"
            local pat_compact="${pat_lower// /}"
            if [[ "$folder_lower" == *"$pat_lower"* ]] || [[ "$folder_compact" == *"$pat_compact"* ]]; then
                echo "$gid"
                return 0
            fi
        done
    done
    return 0
}

scan_appmanifests() {
    log_info "Method A: parsing appmanifest files"

    local lib
    local -a temp_files=()
    local -a pids=()
    local subprocess_failures=0

    for lib in "${STEAM_LIBRARIES[@]}"; do
        # SECURITY: Use secure temp file in user directory
        local tmp
        tmp=$(mktemp -p "$CACHE_DIR" "manifest_scan_XXXXXXXX.tmp") || {
            log_warn "Failed to create temp file for $lib"
            continue
        }
        temp_files+=("$tmp")

        # Run in subshell for parallel processing
        (
            for manifest in "$lib"/appmanifest_*.acf; do
                [[ -f "$manifest" ]] || continue

                declare -A app=()
                parse_appmanifest "$manifest" app || continue

                local app_id="${app[appid]}"
                local name="${app[name]}"
                local installdir="${app[installdir]}"
                local state="${app[stateflags]}"

                # Skip non-installed games (state 4 = fully installed)
                [[ "$state" != "4" ]] && continue

                local install_path="$lib/common/$installdir"

                # Write to temp file for parent to collect
                # Format: app_id|name|install_path|method|installdir_lower
                echo "$app_id|$name|$install_path|appmanifest|${installdir,,}" >> "$tmp"
            done
        ) &
        pids+=($!)
    done

    # Wait for all subprocesses and track failures
    for pid in "${pids[@]}"; do
        if ! wait "$pid"; then
            ((subprocess_failures++)) || true
        fi
    done

    if [[ $subprocess_failures -gt 0 ]]; then
        log_warn "$subprocess_failures manifest scan subprocess(es) had issues"
    fi

    # Process results from all temp files
    for tmp in "${temp_files[@]}"; do
        if [[ ! -f "$tmp" ]]; then
            continue
        fi

        while IFS='|' read -r app_id name install_path method installdir_lower; do
            [[ -z "$app_id" ]] && continue

            # Update MANIFEST_BY_DIR in parent process
            if [[ -n "$installdir_lower" ]]; then
                MANIFEST_BY_DIR["$installdir_lower"]="$app_id|$name|4"
            fi

            if [[ -n "${PROFILE_BY_APPID[$app_id]:-}" ]]; then
                # Skip if already detected
                [[ -n "${DETECTED_BY_APPID[$app_id]:-}" ]] && continue

                local gid
                gid=$(_match_profile_by_appid "$app_id")
                [[ -z "$gid" ]] && continue

                validate_installation "$gid" "$app_id" "$install_path" "$method" || true
            else
                record_unsupported "$app_id" "$name" "$install_path" "$method"
            fi
        done < "$tmp"

        # Cleanup temp file
        rm -f "$tmp"
    done

    return 0
}

resolve_app_by_folder() {
    local folder_base="$1"
    local lib="$2"
    [[ -z "$folder_base" || -z "$lib" ]] && return 1
    local manifest
    for manifest in "$lib"/appmanifest_*.acf; do
        [[ -f "$manifest" ]] || continue
        local installdir
        installdir=$(grep -Po '^\s*"installdir"\s*"\K[^"]+' "$manifest" 2>/dev/null)
        [[ -z "$installdir" ]] && continue
        if [[ "${installdir,,}" == "${folder_base,,}" ]]; then
            local appid name state
            appid=$(grep -Po '^\s*"appid"\s*"\K[^"]+' "$manifest" 2>/dev/null)
            name=$(grep -Po '^\s*"name"\s*"\K[^"]+' "$manifest" 2>/dev/null)
            state=$(grep -Po '^\s*"StateFlags"\s*"\K[^"]+' "$manifest" 2>/dev/null)
            echo "${appid}|${name}|${state}"
            return 0
        fi
    done
    return 1
}

scan_fuzzy_folders() {
    log_info "Method B: fuzzy match on folder names"
    local lib folder gid app_id
    for lib in "${STEAM_LIBRARIES[@]}"; do
        [[ -d "$lib/common" ]] || continue
        while read -r folder; do
            local base="$(basename "$folder")"
            gid=$(_match_profile_by_folder "$base")
            if [[ -z "$gid" ]]; then
                # Try to resolve by installdir mapping from manifests
                local key="$(echo "${base,,}")"
                local manifest_entry="${MANIFEST_BY_DIR["$key"]}"
                if [[ -z "$manifest_entry" ]]; then
                    manifest_entry="$(resolve_app_by_folder "$base" "$lib" || true)"
                fi
                if [[ -n "$manifest_entry" ]]; then
                    local app_id="${manifest_entry%%|*}"
                    local rest="${manifest_entry#*|}"
                    local name="${rest%%|*}"
                    record_unsupported "$app_id" "$name" "$folder" "folder_fuzzy"
                else
                    record_unsupported "" "$base" "$folder" "folder_fuzzy"
                fi
                continue
            fi
            app_id="${PROFILE_APPID[$gid]}"
            [[ -n "${DETECTED_BY_APPID[$app_id]:-}" ]] && continue
            validate_installation "$gid" "$app_id" "$folder" "folder_fuzzy" || true
        done < <(find "$lib/common" -mindepth 1 -maxdepth 1 -type d)
    done
    return 0
}

scan_known_executables() {
    log_info "Method C: known executable markers"
    local lib gid app_id
    for lib in "${STEAM_LIBRARIES[@]}"; do
        [[ -d "$lib/common" ]] || continue
        while IFS= read -r -d '' exe; do
            local folder
            folder="$(dirname "$exe")"
            local parent
            parent="$(basename "$(dirname "$folder")")"
            gid=$(_match_profile_by_folder "$parent")
            if [[ -z "$gid" ]]; then
                # attempt by executable list
                for candidate in "${!PROFILE_PATH[@]}"; do
                    IFS=';' read -r -a exes <<< "${PROFILE_EXECUTABLES[$candidate]}"
                    for e in "${exes[@]}"; do
                        [[ -z "$e" ]] && continue
                        if [[ "$exe" == "$lib/common/"*"/$e" ]]; then
                            gid="$candidate"
                            break
                        fi
                    done
                    [[ -n "$gid" ]] && break
                done
            fi

            [[ -z "$gid" ]] && continue
            app_id="${PROFILE_APPID[$gid]}"
            [[ -n "${DETECTED_BY_APPID[$app_id]:-}" ]] && continue
            local install_path="$lib/common/$parent"
            validate_installation "$gid" "$app_id" "$install_path" "executable_probe" || true
        done < <(find "$lib/common" -maxdepth 4 -type f \( -iname "*.exe" -o -iname "*.sh" \) -print0 2>/dev/null)
    done
    return 0
}

scan_appid_directories() {
    log_info "Method D: AppID presence in compatdata"
    local lib
    for lib in "${STEAM_LIBRARIES[@]}"; do
        local compat="$lib/compatdata"
        [[ -d "$compat" ]] || continue
        for app_dir in "$compat"/*; do
            [[ -d "$app_dir" ]] || continue
            local app_id
            app_id="$(basename "$app_dir")"
            local gid="${PROFILE_BY_APPID[$app_id]}"
            [[ -z "$gid" ]] && continue
            [[ -n "${DETECTED_BY_APPID[$app_id]:-}" ]] && continue
            # Try to resolve installdir from appmanifest if available
            local manifest="$lib/appmanifest_${app_id}.acf"
            local installdir=""
            if [[ -f "$manifest" ]]; then
                declare -A app=()
                parse_appmanifest "$manifest" app
                installdir="${app[installdir]}"
            fi
            local install_path="$lib/common/${installdir:-$gid}"
            validate_installation "$gid" "$app_id" "$install_path" "appid_lookup" || true
        done
    done
    return 0
}

# -----------------------------------------------------------------------------
# Cache handling
# -----------------------------------------------------------------------------

_cache_valid() {
    [[ -f "$CACHE_FILE" ]] || return 1
    local mtime
    mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null) || return 1
    local now
    now=$(date +%s)
    (( now - mtime < CACHE_TTL_SECONDS )) && return 0
    return 1
}

_load_cache() {
    DETECTED_GAMES=()
    DETECTED_BY_APPID=()
    DETECTED_UNSUPPORTED=()
    local section="supported"
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" ]] && continue
        if [[ "$line" == "---UNSUPPORTED---" ]]; then
            section="unsupported"
            continue
        fi
        local app_id
        app_id="$(echo "$line" | tr "$DELIM" '\n' | awk -F= '$1=="app_id"{print $2}' | head -1)"
        if [[ "$section" == "unsupported" ]]; then
            DETECTED_UNSUPPORTED+=("$line")
        else
            DETECTED_GAMES+=("$line")
            [[ -n "$app_id" ]] && DETECTED_BY_APPID["$app_id"]=$(( ${#DETECTED_GAMES[@]} -1 ))
        fi
    done < "$CACHE_FILE"
    log_info "Using cached detection results from $CACHE_FILE"
}

_write_cache() {
    : > "$CACHE_FILE"
    for rec in "${DETECTED_GAMES[@]}"; do
        echo "$rec" >> "$CACHE_FILE"
    done
    echo "---UNSUPPORTED---" >> "$CACHE_FILE"
    for rec in "${DETECTED_UNSUPPORTED[@]}"; do
        echo "$rec" >> "$CACHE_FILE"
    done
}

# -----------------------------------------------------------------------------
# Public entry points
# -----------------------------------------------------------------------------

detect_all_games() {
    load_detection_profiles || return 1
    discover_steam_libraries || return 1

    if [[ "$FORCE_RESCAN" != "true" ]] && _cache_valid; then
        _load_cache
        return 0
    fi

    DETECTED_GAMES=()
    DETECTED_BY_APPID=()

    scan_appmanifests
    scan_fuzzy_folders
    scan_known_executables
    scan_appid_directories

    _write_cache
    return 0
}

print_detected_games_table() {
    if [[ ${#DETECTED_GAMES[@]} -eq 0 ]]; then
        echo "No supported games detected."
    else
        printf "%-28s %-10s %-8s %-5s %-7s %s\n" "Game" "AppID" "Proton" "Write" "Method" "Path"
        printf "%-28s %-10s %-8s %-5s %-7s %s\n" "----------------------------" "------" "------" "-----" "------" "----"
        local rec
        for rec in "${DETECTED_GAMES[@]}"; do
            local game_name app_id is_proton writable method path
            IFS="$DELIM" read -r -a kvs <<< "$rec"
            for kv in "${kvs[@]}"; do
                local k="${kv%%=*}"
                local v="${kv#*=}"
                case "$k" in
                    game_name) game_name="$v" ;;
                    app_id) app_id="$v" ;;
                    is_proton) is_proton="$v" ;;
                    writable) writable="$v" ;;
                    detection_method) method="$v" ;;
                    install_path) path="$v" ;;
                esac
            done
            printf "%-28s %-10s %-8s %-5s %-7s %s\n" "$game_name" "$app_id" "$is_proton" "$writable" "$method" "$path"
        done
    fi

    if [[ ${#DETECTED_UNSUPPORTED[@]} -gt 0 ]]; then
        echo ""
        echo "Detected games without profile (not installed by OptiScaler):"
        printf "%-28s %-10s %-7s %s\n" "Game" "AppID" "Method" "Path"
        printf "%-28s %-10s %-7s %s\n" "----------------------------" "------" "-------" "----"
        local rec2
        for rec2 in "${DETECTED_UNSUPPORTED[@]}"; do
            local game_name app_id method path
            IFS="$DELIM" read -r -a kvs <<< "$rec2"
            for kv in "${kvs[@]}"; do
                local k="${kv%%=*}"
                local v="${kv#*=}"
                case "$k" in
                    game_name) game_name="$v" ;;
                    app_id) app_id="$v" ;;
                    detection_method) method="$v" ;;
                    install_path) path="$v" ;;
                esac
            done
            printf "%-28s %-10s %-7s %s\n" "${game_name:-UNKNOWN}" "${app_id:-UNKNOWN}" "$method" "$path"
        done
    fi
}

export -f detect_all_games
export -f list_supported_games
export -f print_detected_games_table
export -f load_detection_profiles
