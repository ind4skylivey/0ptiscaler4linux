log_section "Installing OptiScaler to Supported Games"

local games_installed=0

for game_profile in "$SCRIPT_DIR/profiles/games"/*.yaml; do
    if [[ ! -f "$game_profile" ]]; then
        continue
    fi
    
    local game_name=$(basename "$game_profile" .yaml)
    local steam_dir=$(grep 'steam_dir:' "$game_profile" | awk '{print $2}' | tr -d '"')
    local app_id=$(grep 'app_id:' "$game_profile" | awk '{print $2}' | tr -d '"')
    
    log_info "Looking for: $game_name (APP: $app_id)"
    
    for lib in "${steam_libraries[@]}"; do
        local game_path="$lib/$steam_dir"
        
        if [[ -d "$game_path" ]]; then
            log_success "Found at: $game_path"
            install_to_game "$game_path" "$app_id"
            ((games_installed++))
        fi
    done
done

log_success "Installation complete - $games_installed game(s) updated"

