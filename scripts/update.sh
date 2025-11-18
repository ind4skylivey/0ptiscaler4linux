#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - UPDATE TOOL
# ═══════════════════════════════════════════════════════════════════════════
#
#  Updates OptiScaler binaries, profiles, and project files
#
#  Usage: bash scripts/update.sh [OPTIONS]
#  Options:
#    --check-only          Check for updates without installing
#    --binaries            Update OptiScaler/fakenvapi binaries only
#    --profiles            Update GPU and game profiles only
#    --force               Force update even if version is current
#
# ═══════════════════════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/utils.sh"

REPO_URL="https://github.com/ind4skylivey/0ptiscaler4linux"
CURRENT_VERSION=$(cat "$SCRIPT_DIR/VERSION" | head -1)

CHECK_ONLY=false
UPDATE_BINARIES=false
UPDATE_PROFILES=false
FORCE_UPDATE=false

# ═══════════════════════════════════════════════════════════════════════════
#  FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

show_banner() {
    clear
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                                                                           ${NC}"
    echo -e "${GREEN}                   OPTISCALER UNIVERSAL UPDATE TOOL                       ${NC}"
    echo -e "${GREEN}                                                                           ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

check_git_available() {
    if ! command_exists git; then
        log_error "git is required for updates"
        log_info "Install git: sudo pacman -S git  (Arch)"
        log_info "            sudo apt install git (Debian/Ubuntu)"
        exit 1
    fi
}

get_latest_version() {
    log_info "Checking for updates..."
    
    local latest_version=""
    
    if command_exists curl; then
        latest_version=$(curl -s "https://raw.githubusercontent.com/ind4skylivey/0ptiscaler4linux/main/VERSION" | head -1)
    elif command_exists wget; then
        latest_version=$(wget -qO- "https://raw.githubusercontent.com/ind4skylivey/0ptiscaler4linux/main/VERSION" | head -1)
    else
        log_error "curl or wget required to check for updates"
        return 1
    fi
    
    if [ -z "$latest_version" ]; then
        log_warn "Could not fetch latest version"
        return 1
    fi
    
    echo "$latest_version"
    return 0
}

compare_versions() {
    local current="$1"
    local latest="$2"
    
    if [ "$current" = "$latest" ]; then
        return 0  # Same version
    else
        return 1  # Different version
    fi
}

check_for_updates() {
    log_section "Version Check"
    
    echo -e "${CYAN}Current Version:${NC}  $CURRENT_VERSION"
    
    local latest_version=$(get_latest_version)
    
    if [ $? -ne 0 ]; then
        log_error "Failed to check for updates"
        return 1
    fi
    
    echo -e "${CYAN}Latest Version:${NC}   $latest_version"
    echo ""
    
    if compare_versions "$CURRENT_VERSION" "$latest_version"; then
        log_success "You are running the latest version!"
        return 0
    else
        log_info "Update available: $CURRENT_VERSION → $latest_version"
        return 1
    fi
}

backup_current_installation() {
    log_info "Creating backup of current installation..."
    
    local backup_dir="$HOME/.optiscaler-universal/backups/update_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    cp -r "$SCRIPT_DIR"/{core,lib,profiles,scripts,templates} "$backup_dir/" 2>/dev/null || true
    cp "$SCRIPT_DIR/VERSION" "$backup_dir/" 2>/dev/null || true
    
    echo "$backup_dir" > "$HOME/.optiscaler-universal/last_update_backup"
    
    log_success "Backup created: $backup_dir"
}

update_project() {
    log_section "Updating OptiScaler Universal"
    
    if [ ! -d "$SCRIPT_DIR/.git" ]; then
        log_error "Not a git repository. Please clone from: $REPO_URL"
        return 1
    fi
    
    backup_current_installation
    
    log_info "Fetching updates from repository..."
    
    cd "$SCRIPT_DIR"
    
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    
    if ! git fetch origin; then
        log_error "Failed to fetch updates"
        return 1
    fi
    
    log_info "Applying updates..."
    
    if ! git pull origin "$current_branch"; then
        log_error "Failed to apply updates"
        log_warn "You may need to resolve conflicts manually"
        return 1
    fi
    
    local new_version=$(cat "$SCRIPT_DIR/VERSION" | head -1)
    
    log_success "Updated successfully: $CURRENT_VERSION → $new_version"
    
    echo ""
    log_info "Changelog:"
    git log --oneline --no-merges "HEAD@{1}..HEAD" | head -10
    echo ""
}

update_binaries() {
    log_section "Updating Binaries"
    
    log_info "Checking for binary updates..."
    
    local optiscaler_latest="0.7.9"
    local fakenvapi_latest="1.3.4"
    
    log_info "OptiScaler latest: $optiscaler_latest"
    log_info "fakenvapi latest: $fakenvapi_latest"
    
    echo ""
    log_warn "Binary updates require Git LFS"
    log_info "Run: git lfs pull"
    echo ""
    
    if command_exists git-lfs || git lfs version &>/dev/null; then
        log_info "Pulling binary updates..."
        cd "$SCRIPT_DIR"
        git lfs pull
        log_success "Binaries updated"
    else
        log_warn "Git LFS not installed"
        log_info "Install: sudo pacman -S git-lfs  (Arch)"
        log_info "        sudo apt install git-lfs (Debian/Ubuntu)"
        log_info "Then run: git lfs install && git lfs pull"
    fi
}

update_profiles() {
    log_section "Updating Profiles"
    
    if [ ! -d "$SCRIPT_DIR/.git" ]; then
        log_error "Not a git repository"
        return 1
    fi
    
    cd "$SCRIPT_DIR"
    
    log_info "Fetching profile updates..."
    
    if ! git pull origin main -- profiles/; then
        log_error "Failed to update profiles"
        return 1
    fi
    
    local gpu_profiles=$(ls -1 "$SCRIPT_DIR/profiles/gpu/"*.yaml 2>/dev/null | wc -l)
    local game_profiles=$(ls -1 "$SCRIPT_DIR/profiles/games/"*.yaml 2>/dev/null | wc -l)
    
    log_success "Profiles updated"
    log_info "GPU Profiles: $gpu_profiles"
    log_info "Game Profiles: $game_profiles"
}

show_update_summary() {
    log_section "Update Summary"
    
    echo -e "${GREEN}✓ Update completed successfully${NC}"
    echo ""
    echo "What's new:"
    echo "  - Check VERSION file for changelog"
    echo "  - Review PROJECT_DESIGN.md for new features"
    echo "  - See README.md for updated documentation"
    echo ""
    
    if [ -f "$HOME/.optiscaler-universal/last_update_backup" ]; then
        local backup=$(cat "$HOME/.optiscaler-universal/last_update_backup")
        echo "Backup location: $backup"
        echo ""
    fi
    
    log_info "To apply updates to installed games, re-run:"
    echo "  ${CYAN}bash scripts/install.sh${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════════════════

main() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --check-only)
                CHECK_ONLY=true
                shift
                ;;
            --binaries)
                UPDATE_BINARIES=true
                shift
                ;;
            --profiles)
                UPDATE_PROFILES=true
                shift
                ;;
            --force)
                FORCE_UPDATE=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    show_banner
    
    check_git_available
    
    if check_for_updates; then
        if [ "$FORCE_UPDATE" = false ]; then
            log_info "No update needed"
            exit 0
        fi
    fi
    
    if [ "$CHECK_ONLY" = true ]; then
        exit 0
    fi
    
    echo ""
    
    if [ "$UPDATE_BINARIES" = true ]; then
        update_binaries
        exit 0
    fi
    
    if [ "$UPDATE_PROFILES" = true ]; then
        update_profiles
        exit 0
    fi
    
    if ! prompt_yes_no "Do you want to update now?"; then
        log_info "Update cancelled"
        exit 0
    fi
    
    update_project
    show_update_summary
    
    log_success "All done!"
}

main "$@"
