#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - STEAM GAME SCANNER
# ═══════════════════════════════════════════════════════════════════════════
#
#  Scans Steam library for installed games and matches with profiles
#
#  Usage: source core/game-scanner.sh && scan_steam_games
#
# ═══════════════════════════════════════════════════════════════════════════

# Array to store found games
declare -a FOUND_GAMES=()

# ═══════════════════════════════════════════════════════════════════════════
#  Find Steam Library Folders
# ═══════════════════════════════════════════════════════════════════════════

find_steam_libraries() {
    local steam_dirs=()
    
    # Default Steam location
    local default_steam="$HOME/.local/share/Steam"
    
    if [ -d "$default_steam" ]; then
        steam_dirs+=("$default_steam")
        log_debug "Found default Steam directory: $default_steam"
    fi
    
    # Check for additional library folders
    local libraryfolders="$default_steam/steamapps/libraryfolders.vdf"
    
    if [ -f "$libraryfolders" ]; then
        log_debug "Parsing libraryfolders.vdf"
        
        # Extract paths from libraryfolders.vdf
        while IFS= read -r line; do
            if [[ $line =~ \"path\"[[:space:]]*\"([^\"]+)\" ]]; then
                local lib_path="${BASH_REMATCH[1]}"
                if [ -d "$lib_path/steamapps" ]; then
                    steam_dirs+=("$lib_path")
                    log_debug "Found additional library: $lib_path"
                fi
            fi
        done < "$libraryfolders"
    fi
    
    echo "${steam_dirs[@]}"
}

# ═══════════════════════════════════════════════════════════════════════════
#  Scan for Installed Games
# ═══════════════════════════════════════════════════════════════════════════

scan_steam_games() {
    log_info "Scanning Steam library for games..."
    
    FOUND_GAMES=()
    
    # Get all Steam library directories
    local steam_libs=($(find_steam_libraries))
    
    if [ ${#steam_libs[@]} -eq 0 ]; then
        log_warn "No Steam installation found"
        return 1
    fi
    
    log_info "Found ${#steam_libs[@]} Steam library location(s)"
    
    # Get all available game profiles
    local profile_dir="$SCRIPT_DIR/profiles/games"
    local total_games=0
    local matched_games=0
    
    # Scan each library
    for steam_lib in "${steam_libs[@]}"; do
        local steamapps="$steam_lib/steamapps"
        
        if [ ! -d "$steamapps" ]; then
            continue
        fi
        
        log_debug "Scanning: $steamapps"
        
        # Find all app manifest files
        for manifest in "$steamapps"/appmanifest_*.acf; do
            if [ ! -f "$manifest" ]; then
                continue
            fi
            
            ((total_games++))
            
            # Extract appid and name from manifest
            local appid=$(basename "$manifest" | sed 's/appmanifest_//;s/.acf//')
            local game_name=$(grep -Po '^\s*"name"\s*"\K[^"]+' "$manifest" 2>/dev/null)
            local install_dir=$(grep -Po '^\s*"installdir"\s*"\K[^"]+' "$manifest" 2>/dev/null)
            
            if [ -z "$game_name" ]; then
                continue
            fi
            
            log_trace "Checking: $game_name (AppID: $appid)"
            
            # Check if we have a profile for this game
            local profile_match=$(check_game_profile "$appid" "$game_name" "$install_dir")
            
            if [ -n "$profile_match" ]; then
                ((matched_games++))
                FOUND_GAMES+=("$appid|$game_name|$install_dir|$profile_match")
                log_info "✓ Found supported game: $game_name"
            fi
        done
    done
    
    log_info "Scan complete: $matched_games supported games found (out of $total_games installed)"
    
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════
#  Check if Game Has Profile
# ═══════════════════════════════════════════════════════════════════════════

check_game_profile() {
    local appid="$1"
    local game_name="$2"
    local install_dir="$3"
    
    local profile_dir="$SCRIPT_DIR/profiles/games"
    
    # List of known game profiles with their Steam AppIDs
    declare -A KNOWN_GAMES=(
        ["1091500"]="cyberpunk2077"
        ["1063730"]="newworld"
        ["1716740"]="starfield"
        ["1174180"]="rdr2"
        ["1817070"]="spiderman"
        ["1593500"]="godofwar"
        ["990080"]="hogwartslegacy"
        ["292030"]="witcher3"
        ["1245620"]="eldenring"
    )
    
    # Check by AppID first (most reliable)
    if [ -n "${KNOWN_GAMES[$appid]}" ]; then
        local profile_name="${KNOWN_GAMES[$appid]}"
        if [ -f "$profile_dir/$profile_name.yaml" ]; then
            echo "$profile_name"
            return 0
        fi
    fi
    
    # Check by install directory name
    for profile in "$profile_dir"/*.yaml; do
        if [ ! -f "$profile" ]; then
            continue
        fi
        
        local profile_name=$(basename "$profile" .yaml)
        
        # Simple matching by name similarity
        if [[ "${install_dir,,}" == *"${profile_name,,}"* ]] || \
           [[ "${profile_name,,}" == *"${install_dir,,}"* ]]; then
            echo "$profile_name"
            return 0
        fi
    done
    
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════
#  Display Found Games
# ═══════════════════════════════════════════════════════════════════════════

display_found_games() {
    if [ ${#FOUND_GAMES[@]} -eq 0 ]; then
        echo -e "${YELLOW}No supported games found in your Steam library.${NC}"
        echo ""
        echo "Supported games:"
        echo "  • Cyberpunk 2077"
        echo "  • New World"
        echo "  • Starfield"
        echo "  • Red Dead Redemption 2"
        echo "  • Spider-Man Remastered"
        echo "  • God of War"
        echo "  • Hogwarts Legacy"
        echo "  • The Witcher 3"
        echo "  • Elden Ring"
        return 1
    fi
    
    echo -e "${GREEN}Found ${#FOUND_GAMES[@]} supported game(s):${NC}"
    echo ""
    
    local index=1
    for game_entry in "${FOUND_GAMES[@]}"; do
        IFS='|' read -r appid name install_dir profile <<< "$game_entry"
        echo -e "  ${CYAN}$index)${NC} $name"
        echo -e "      Profile: ${GREEN}$profile${NC}"
        echo ""
        ((index++))
    done
}

# ═══════════════════════════════════════════════════════════════════════════
#  Get Game Info by Index
# ═══════════════════════════════════════════════════════════════════════════

get_game_by_index() {
    local index=$1
    
    if [ "$index" -lt 1 ] || [ "$index" -gt "${#FOUND_GAMES[@]}" ]; then
        return 1
    fi
    
    echo "${FOUND_GAMES[$((index-1))]}"
}

# Export functions
export -f find_steam_libraries
export -f scan_steam_games
export -f check_game_profile
export -f display_found_games
export -f get_game_by_index
