#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  OPTISCALER UNIVERSAL - BENCHMARK TOOL
# ═══════════════════════════════════════════════════════════════════════════
#
#  Benchmarks performance with and without OptiScaler
#
#  Usage: bash scripts/benchmark.sh [OPTIONS]
#  Options:
#    --game <name>         Game to benchmark
#    --game-dir <path>     Game directory path
#    --runs <number>       Number of test runs (default: 3)
#    --duration <seconds>  Duration per run (default: 60)
#    --output <file>       Save results to file
#
# ═══════════════════════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/utils.sh"

GAME_NAME=""
GAME_DIR=""
NUM_RUNS=3
DURATION=60
OUTPUT_FILE=""

# ═══════════════════════════════════════════════════════════════════════════
#  FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

show_banner() {
    clear
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}                                                                           ${NC}"
    echo -e "${YELLOW}                  OPTISCALER UNIVERSAL BENCHMARK TOOL                     ${NC}"
    echo -e "${YELLOW}                                                                           ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

check_requirements() {
    log_section "Checking Benchmark Requirements"
    
    local requirements_met=true
    
    if ! command_exists mangohud; then
        log_warn "MangoHud not found (recommended for FPS logging)"
        log_info "Install: sudo pacman -S mangohud (Arch)"
        log_info "        sudo apt install mangohud (Debian/Ubuntu)"
        requirements_met=false
    else
        log_success "MangoHud found"
    fi
    
    if ! command_exists gamemoderun; then
        log_warn "GameMode not found (recommended for consistent performance)"
        log_info "Install: sudo pacman -S gamemode (Arch)"
        log_info "        sudo apt install gamemode (Debian/Ubuntu)"
    else
        log_success "GameMode found"
    fi
    
    echo ""
    
    if [ "$requirements_met" = false ]; then
        log_warn "Some optional tools are missing, but continuing..."
    fi
}

backup_game_files() {
    local game_dir="$1"
    local backup_dir="/tmp/optiscaler_bench_backup_$$"
    
    mkdir -p "$backup_dir"
    
    local files=("dxgi.dll" "OptiScaler.ini" "nvapi64.dll" "fakenvapi.ini")
    
    for file in "${files[@]}"; do
        if [ -f "$game_dir/$file" ]; then
            cp "$game_dir/$file" "$backup_dir/"
        fi
    done
    
    echo "$backup_dir"
}

restore_game_files() {
    local game_dir="$1"
    local backup_dir="$2"
    
    if [ ! -d "$backup_dir" ]; then
        log_error "Backup directory not found: $backup_dir"
        return 1
    fi
    
    cp "$backup_dir"/* "$game_dir/" 2>/dev/null || true
    rm -rf "$backup_dir"
    
    log_info "Game files restored"
}

disable_optiscaler() {
    local game_dir="$1"
    
    log_info "Disabling OptiScaler for baseline test..."
    
    local files=("dxgi.dll" "nvapi64.dll")
    
    for file in "${files[@]}"; do
        if [ -f "$game_dir/$file" ]; then
            mv "$game_dir/$file" "$game_dir/$file.disabled"
        fi
    done
}

enable_optiscaler() {
    local game_dir="$1"
    
    log_info "Enabling OptiScaler..."
    
    local files=("dxgi.dll" "nvapi64.dll")
    
    for file in "${files[@]}"; do
        if [ -f "$game_dir/$file.disabled" ]; then
            mv "$game_dir/$file.disabled" "$game_dir/$file"
        fi
    done
}

run_benchmark() {
    local game_dir="$1"
    local run_name="$2"
    local run_number="$3"
    
    log_info "Running benchmark: $run_name (Run $run_number/$NUM_RUNS)"
    
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  BENCHMARK: $run_name - Run $run_number${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Instructions:"
    echo "1. The game will start shortly"
    echo "2. Load your save or start a benchmark scene"
    echo "3. Play normally for $DURATION seconds"
    echo "4. The benchmark will automatically stop"
    echo ""
    echo -e "${CYAN}Press Enter when ready to start...${NC}"
    read
    
    local log_file="/tmp/mangohud_$run_name_$run_number.log"
    
    export MANGOHUD_LOG=1
    export MANGOHUD_LOGFILE="$log_file"
    export MANGOHUD_CONFIG="fps_limit=0,fps_only=1"
    
    log_info "Starting game... (Duration: ${DURATION}s)"
    log_warn "Please start playing/benchmarking NOW"
    
    timeout "$DURATION" steam -applaunch <APP_ID> 2>/dev/null || true
    
    unset MANGOHUD_LOG MANGOHUD_LOGFILE MANGOHUD_CONFIG
    
    if [ -f "$log_file" ]; then
        log_success "Benchmark data collected: $log_file"
        echo "$log_file"
    else
        log_warn "No benchmark data collected (MangoHud log not found)"
        echo ""
    fi
    
    sleep 5
}

parse_benchmark_results() {
    local log_file="$1"
    
    if [ ! -f "$log_file" ]; then
        echo "N/A"
        return
    fi
    
    local avg_fps=$(awk '{sum+=$1; count++} END {if(count>0) print sum/count; else print 0}' "$log_file")
    local min_fps=$(sort -n "$log_file" | head -1)
    local max_fps=$(sort -n "$log_file" | tail -1)
    
    printf "%.2f|%.2f|%.2f" "$avg_fps" "$min_fps" "$max_fps"
}

compare_results() {
    local baseline_logs="$1"
    local optiscaler_logs="$2"
    
    log_section "Benchmark Results Comparison"
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf "%-20s %-15s %-15s %-15s %-15s\n" "Configuration" "Avg FPS" "Min FPS" "Max FPS" "Improvement"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local baseline_avg=0
    local baseline_count=0
    
    for log in $baseline_logs; do
        if [ -f "$log" ]; then
            IFS='|' read -r avg min max <<< "$(parse_benchmark_results "$log")"
            baseline_avg=$(echo "$baseline_avg + $avg" | bc)
            baseline_count=$((baseline_count + 1))
        fi
    done
    
    if [ $baseline_count -gt 0 ]; then
        baseline_avg=$(echo "scale=2; $baseline_avg / $baseline_count" | bc)
    fi
    
    printf "%-20s %-15.2f %-15s %-15s %-15s\n" "Baseline (Native)" "$baseline_avg" "-" "-" "-"
    
    local optiscaler_avg=0
    local optiscaler_count=0
    
    for log in $optiscaler_logs; do
        if [ -f "$log" ]; then
            IFS='|' read -r avg min max <<< "$(parse_benchmark_results "$log")"
            optiscaler_avg=$(echo "$optiscaler_avg + $avg" | bc)
            optiscaler_count=$((optiscaler_count + 1))
        fi
    done
    
    if [ $optiscaler_count -gt 0 ]; then
        optiscaler_avg=$(echo "scale=2; $optiscaler_avg / $optiscaler_count" | bc)
    fi
    
    local improvement="N/A"
    if [ "$baseline_avg" != "0" ]; then
        improvement=$(echo "scale=2; (($optiscaler_avg - $baseline_avg) / $baseline_avg) * 100" | bc)
        improvement="${improvement}%"
    fi
    
    printf "%-20s %-15.2f %-15s %-15s ${GREEN}%-15s${NC}\n" "OptiScaler" "$optiscaler_avg" "-" "-" "$improvement"
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ "$baseline_avg" != "0" ] && [ "$optiscaler_avg" != "0" ]; then
        local fps_gain=$(echo "scale=2; $optiscaler_avg - $baseline_avg" | bc)
        
        echo -e "${GREEN}Performance Summary:${NC}"
        echo "  Average FPS gain: ${GREEN}+${fps_gain} FPS${NC} (${improvement})"
        
        if (( $(echo "$fps_gain > 0" | bc -l) )); then
            log_success "OptiScaler improved performance!"
        elif (( $(echo "$fps_gain < 0" | bc -l) )); then
            log_warn "Performance decreased (check configuration)"
        else
            log_info "No significant performance difference"
        fi
    else
        log_warn "Insufficient data for comparison"
    fi
    
    echo ""
}

save_results() {
    local output_file="$1"
    local baseline_logs="$2"
    local optiscaler_logs="$3"
    
    {
        echo "OptiScaler Universal - Benchmark Results"
        echo "Generated: $(date)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Game: $GAME_NAME"
        echo "Game Directory: $GAME_DIR"
        echo "Number of Runs: $NUM_RUNS"
        echo "Duration per Run: ${DURATION}s"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        # Add detailed results here
        
    } > "$output_file"
    
    log_success "Results saved to: $output_file"
}

# ═══════════════════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════════════════

main() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --game)
                GAME_NAME="$2"
                shift 2
                ;;
            --game-dir)
                GAME_DIR="$2"
                shift 2
                ;;
            --runs)
                NUM_RUNS="$2"
                shift 2
                ;;
            --duration)
                DURATION="$2"
                shift 2
                ;;
            --output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    show_banner
    
    if [ -z "$GAME_DIR" ]; then
        log_error "Game directory required: --game-dir <path>"
        exit 1
    fi
    
    if [ ! -d "$GAME_DIR" ]; then
        log_error "Game directory not found: $GAME_DIR"
        exit 1
    fi
    
    check_requirements
    
    log_section "Benchmark Configuration"
    echo -e "${CYAN}Game:${NC}             $GAME_NAME"
    echo -e "${CYAN}Directory:${NC}        $GAME_DIR"
    echo -e "${CYAN}Runs:${NC}             $NUM_RUNS"
    echo -e "${CYAN}Duration:${NC}         ${DURATION}s per run"
    echo ""
    
    log_warn "This benchmark requires manual gameplay"
    log_info "Try to maintain consistent gameplay between runs"
    echo ""
    
    if ! prompt_yes_no "Start benchmark?"; then
        log_info "Benchmark cancelled"
        exit 0
    fi
    
    local backup_dir=$(backup_game_files "$GAME_DIR")
    log_success "Game files backed up to: $backup_dir"
    echo ""
    
    log_warn "Benchmark tool is currently a prototype"
    log_info "Automated benchmarking requires game-specific integration"
    log_info "For now, please manually compare performance with/without OptiScaler"
    echo ""
    
    restore_game_files "$GAME_DIR" "$backup_dir"
    
    log_info "Manual benchmark steps:"
    echo "1. Test game WITHOUT OptiScaler (disable via uninstall.sh)"
    echo "2. Note average FPS in consistent scene/area"
    echo "3. Install OptiScaler (via install.sh)"
    echo "4. Test same scene/area again"
    echo "5. Compare results"
    echo ""
    
    log_success "Benchmark setup complete"
}

main "$@"
