#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - UNINSTALLER
# ═══════════════════════════════════════════════════════════════════════════
#
#  Safely removes OptiScaler installations and optionally restores backups
#
#  Usage: bash scripts/uninstall.sh [OPTIONS]
#  Options:
#    --game-dir <path>     Specific game directory to uninstall from
#    --restore <backup_id> Restore specific backup
#    --all                 Remove all OptiScaler installations
#    --clean               Remove all configs and backups
#
# ═══════════════════════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/utils.sh"

CONFIG_DIR="$HOME/.optiscaler-universal"
BACKUP_DIR="$CONFIG_DIR/backups"

# ═══════════════════════════════════════════════════════════════════════════
#  FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

show_banner() {
    clear
    echo -e "${RED}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}                                                                           ${NC}"
    echo -e "${RED}                   OPTISCALER UNIVERSAL UNINSTALLER                       ${NC}"
    echo -e "${RED}                                                                           ${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

list_backups() {
    log_section "Available Backups"

    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        log_warn "No backups found"
        return 1
    fi

    local count=0
    for backup in "$BACKUP_DIR"/*; do
        if [ -d "$backup" ]; then
            count=$((count + 1))
            local backup_id=$(basename "$backup")
            local manifest="$backup/MANIFEST.txt"

            echo -e "${CYAN}[$count]${NC} Backup ID: ${GREEN}$backup_id${NC}"

            if [ -f "$manifest" ]; then
                grep "^Game:" "$manifest" 2>/dev/null || echo "  Game: Unknown"
                grep "^Date:" "$manifest" 2>/dev/null || echo "  Date: Unknown"
            fi
            echo ""
        fi
    done

    if [ $count -eq 0 ]; then
        log_warn "No valid backups found"
        return 1
    fi

    return 0
}

restore_backup() {
    local backup_id="$1"
    local backup_path="$BACKUP_DIR/$backup_id"

    if [ ! -d "$backup_path" ]; then
        log_error "Backup not found: $backup_id"
        return 1
    fi

    log_info "Restoring backup: $backup_id"

    local manifest="$backup_path/MANIFEST.txt"
    if [ ! -f "$manifest" ]; then
        log_error "Invalid backup: MANIFEST.txt not found"
        return 1
    fi

    local game_dir=$(grep "^Game Directory:" "$manifest" | cut -d: -f2- | xargs)

    if [ -z "$game_dir" ]; then
        log_warn "Game directory not found in manifest, please specify manually"
        read -p "Enter game directory path: " game_dir
    fi

    if [ ! -d "$game_dir" ]; then
        log_error "Game directory does not exist: $game_dir"
        return 1
    fi

    log_info "Restoring files to: $game_dir"

    local files_restored=0
    for file in "$backup_path"/*; do
        if [ -f "$file" ] && [ "$(basename "$file")" != "MANIFEST.txt" ]; then
            local filename=$(basename "$file")
            cp "$file" "$game_dir/" && {
                log_success "Restored: $filename"
                files_restored=$((files_restored + 1))
            }
        fi
    done

    if [ $files_restored -gt 0 ]; then
        log_success "Backup restored successfully: $files_restored file(s)"
        return 0
    else
        log_error "No files were restored"
        return 1
    fi
}

uninstall_from_directory() {
    local game_dir="$1"

    if [ ! -d "$game_dir" ]; then
        log_error "Directory does not exist: $game_dir"
        return 1
    fi

    log_info "Uninstalling OptiScaler from: $game_dir"

    local files_to_remove=(
        "dxgi.dll"
        "nvapi64.dll"
        "OptiScaler.ini"
        "fakenvapi.ini"
        "OptiScaler.log"
        "fakenvapi.log"
    )

    local files_removed=0

    for file in "${files_to_remove[@]}"; do
        local file_path="$game_dir/$file"
        if [ -f "$file_path" ]; then
            rm -f "$file_path" && {
                log_success "Removed: $file"
                files_removed=$((files_removed + 1))
            }
        fi
    done

    if [ $files_removed -eq 0 ]; then
        log_warn "No OptiScaler files found in: $game_dir"
        return 1
    fi

    log_success "Uninstalled successfully: $files_removed file(s) removed"
    return 0
}

find_and_uninstall_all() {
    log_section "Scanning for OptiScaler Installations"

    # Source game scanner if available
    if [[ -f "$SCRIPT_DIR/core/game-scanner.sh" ]]; then
        source "$SCRIPT_DIR/core/game-scanner.sh"
    else
        log_warn "game-scanner.sh not found, using fallback method"
    fi

    local installations_found=0

    # Default Steam locations
    local -a steam_roots=(
        "$HOME/.steam/steam"
        "$HOME/.local/share/Steam"
    )

    # Scan each Steam root
    for root in "${steam_roots[@]}"; do
        [[ ! -d "$root" ]] && continue

        local common="$root/steamapps/common"
        if [[ -d "$common" ]]; then
            for game in "$common"/*; do
                [[ ! -d "$game" ]] && continue

                if [[ -f "$game/dxgi.dll" ]] || [[ -f "$game/OptiScaler.ini" ]] || [[ -f "$game/OptiScaler.dll" ]]; then
                    ((installations_found++)) || true
                    echo -e "${YELLOW}Found installation in:${NC} $game"

                    if prompt_yes_no "Uninstall from this location?"; then
                        uninstall_from_directory "$game"
                    fi
                    echo ""
                fi
            done
        fi
    done

    if [[ $installations_found -eq 0 ]]; then
        log_info "No OptiScaler installations found"
    else
        log_success "Scan complete: $installations_found installation(s) found"
    fi
}

clean_all_data() {
    log_section "Cleaning All OptiScaler Universal Data"

    echo -e "${RED}WARNING:${NC} This will remove:"
    echo "  - All backups"
    echo "  - All logs"
    echo "  - All generated configurations"
    echo "  - User preferences"
    echo ""

    if ! prompt_yes_no "Are you sure you want to continue?" "n"; then
        log_info "Operation cancelled"
        return 0
    fi

    # SECURITY: Validate CONFIG_DIR before rm -rf
    local expected_dir="$HOME/.optiscaler-universal"
    if [[ -z "$CONFIG_DIR" ]]; then
        log_error "CONFIG_DIR is not set"
        return 1
    fi

    if [[ "$CONFIG_DIR" != "$expected_dir" ]]; then
        log_error "CONFIG_DIR ($CONFIG_DIR) does not match expected path ($expected_dir)"
        log_error "Refusing to remove for safety"
        return 1
    fi

    if [[ -d "$CONFIG_DIR" ]]; then
        rm -rf "${CONFIG_DIR:?}" && {
            log_success "Removed: $CONFIG_DIR"
        }
    else
        log_warn "Config directory not found: $CONFIG_DIR"
    fi

    log_success "All data cleaned"
}

# ═══════════════════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════════════════

main() {
    show_banner

    local game_dir=""
    local backup_id=""
    local uninstall_all=false
    local clean_data=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --game-dir)
                if [[ -z "${2:-}" || "$2" == --* ]]; then
                    log_error "--game-dir requires a path argument"
                    exit 1
                fi
                game_dir="$2"
                shift 2
                ;;
            --restore)
                if [[ -z "${2:-}" || "$2" == --* ]]; then
                    log_error "--restore requires a backup ID argument"
                    exit 1
                fi
                backup_id="$2"
                shift 2
                ;;
            --all)
                uninstall_all=true
                shift
                ;;
            --clean)
                clean_data=true
                shift
                ;;
            -h|--help)
                echo "Usage: $(basename "$0") [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --game-dir <path>     Uninstall from specific game directory"
                echo "  --restore <backup_id> Restore a specific backup"
                echo "  --all                 Scan and uninstall from all games"
                echo "  --clean               Remove all OptiScaler data"
                echo "  -h, --help            Show this help"
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                echo "Use --help for usage information."
                exit 1
                ;;
            *)
                log_error "Unexpected argument: $1"
                exit 1
                ;;
        esac
    done

    if [ -n "$backup_id" ]; then
        restore_backup "$backup_id"
        exit $?
    fi

    if [ "$clean_data" = true ]; then
        clean_all_data
        exit $?
    fi

    if [ "$uninstall_all" = true ]; then
        find_and_uninstall_all
        exit $?
    fi

    if [ -n "$game_dir" ]; then
        uninstall_from_directory "$game_dir"
        exit $?
    fi

    log_info "OptiScaler Universal Uninstaller"
    echo ""
    echo "Available options:"
    echo "  1) Uninstall from specific game directory"
    echo "  2) Scan and uninstall from all detected games"
    echo "  3) List and restore backups"
    echo "  4) Clean all data (backups, logs, configs)"
    echo "  5) Exit"
    echo ""

    read -p "Select option [1-5]: " choice
    echo ""

    case $choice in
        1)
            read -p "Enter game directory path: " game_dir
            uninstall_from_directory "$game_dir"
            ;;
        2)
            find_and_uninstall_all
            ;;
        3)
            list_backups && {
                read -p "Enter backup ID to restore (or press Enter to cancel): " backup_id
                if [ -n "$backup_id" ]; then
                    restore_backup "$backup_id"
                fi
            }
            ;;
        4)
            clean_all_data
            ;;
        5)
            log_info "Exiting"
            exit 0
            ;;
        *)
            log_error "Invalid option"
            exit 1
            ;;
    esac
}

main "$@"
