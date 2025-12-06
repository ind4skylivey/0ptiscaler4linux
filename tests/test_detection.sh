#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export OPTISCALER_SKIP_DEFAULTS=true

# Use local modules
source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/src/modules/steam_parser.sh"
source "$SCRIPT_DIR/src/modules/game_detector.sh"

LOG_LEVEL=DEBUG
CURRENT_LOG_LEVEL=${LOG_LEVELS[$LOG_LEVEL]}
FORCE_RESCAN=true

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

# ---------------------------------------------------------------------------
# Fake Steam layout
# ---------------------------------------------------------------------------
steam_root="$tmp_root/steam"
steamapps="$steam_root/steamapps"
mkdir -p "$steamapps/common/Cyberpunk 2077/bin/x64" "$steamapps/compatdata/1091500/pfx"

cat > "$steamapps/libraryfolders.vdf" <<EOF
"libraryfolders"
{
    "0"
    {
        "path" "$steam_root"
        "label" ""
        "contentid" "123"
    }
}
EOF

cat > "$steamapps/appmanifest_1091500.acf" <<'EOF'
"AppState"
{
    "appid"      "1091500"
    "Universe"   "1"
    "name"       "Cyberpunk 2077"
    "StateFlags" "4"
    "installdir" "Cyberpunk 2077"
}
EOF

touch "$steamapps/common/Cyberpunk 2077/bin/x64/Cyberpunk2077.exe"

# Hint detector to use the fake Steam root
export OPTISCALER_STEAM_HINTS="$steam_root"
export CACHE_FILE="$tmp_root/cache.json"
export PROFILES_DIR="$SCRIPT_DIR/config/games"
detect_all_games
echo "Libraries counted: ${#STEAM_LIBRARIES[@]}"

if [[ ${#DETECTED_GAMES[@]} -eq 0 ]]; then
    echo "Detection failed: no games found"
    declare -p DETECTED_GAMES || true
    exit 1
fi

echo "Detected ${#DETECTED_GAMES[@]} game(s) in simulated environment."
print_detected_games_table
