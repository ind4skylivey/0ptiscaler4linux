# OptiScaler Universal - Project Design Document

## 🎯 Project Vision

A comprehensive, automated solution for Linux gamers to unlock the full potential of their GPUs through intelligent OptiScaler configuration, regardless of GPU vendor (AMD, Intel, NVIDIA) or game.

## 🏗️ Architecture Overview

```
optiscaler-universal/
├── core/
│   ├── detector.sh              # GPU & system detection
│   ├── configurator.sh          # Configuration generator
│   ├── installer.sh             # File installation logic
│   └── validator.sh             # Post-install validation
│
├── profiles/
│   ├── gpu/
│   │   ├── amd-rdna4.yaml
│   │   ├── amd-rdna3.yaml
│   │   ├── amd-rdna2.yaml
│   │   ├── amd-rdna1.yaml
│   │   ├── amd-gcn.yaml
│   │   ├── intel-arc.yaml
│   │   ├── intel-integrated.yaml
│   │   └── nvidia-rtx.yaml
│   │
│   └── games/
│       ├── cyberpunk2077.yaml
│       ├── starfield.yaml
│       ├── newworld.yaml
│       ├── rdr2.yaml
│       └── generic.yaml
│
├── binaries/
│   ├── optiscaler/
│   │   └── 0.7.9/              # Version-specific binaries
│   ├── fakenvapi/
│   │   └── 1.3.4/
│   └── checksums.txt           # SHA256 checksums for security
│
├── templates/
│   ├── OptiScaler.ini.template
│   ├── fakenvapi.ini.template
│   └── steam-launch.template
│
├── scripts/
│   ├── install.sh              # Main installer (user-facing)
│   ├── uninstall.sh            # Clean uninstaller
│   ├── update.sh               # Update OptiScaler/profiles
│   ├── diagnose.sh             # Troubleshooting tool
│   └── benchmark.sh            # Performance comparison tool
│
├── lib/
│   ├── utils.sh                # Common utilities
│   ├── colors.sh               # Terminal colors
│   ├── logging.sh              # Logging system
│   └── steam.sh                # Steam integration
│
├── tests/
│   ├── test-detector.sh
│   ├── test-configurator.sh
│   └── test-integration.sh
│
├── docs/
│   ├── README.md
│   ├── INSTALLATION.md
│   ├── CONTRIBUTING.md
│   ├── GPU_PROFILES.md
│   ├── GAME_SUPPORT.md
│   └── TROUBLESHOOTING.md
│
├── .github/
│   ├── workflows/
│   │   ├── ci.yml              # Continuous Integration
│   │   └── release.yml         # Automated releases
│   └── ISSUE_TEMPLATE/
│
├── LICENSE
├── .gitignore
├── .gitattributes
└── VERSION
```

## 🎮 Core Features

### 1. Intelligent GPU Detection
- **Automatic vendor detection** (AMD, Intel, NVIDIA)
- **Architecture detection** (RDNA1/2/3/4, GCN, Arc, Ada, Ampere, etc.)
- **Capability analysis** (Anti-Lag 2 support, XeSS native, etc.)
- **Driver version checking** (Mesa, NVIDIA proprietary)

### 2. Game Discovery
- **Steam library scanning**
- **Lutris integration**
- **Heroic Games Launcher support**
- **Manual game path addition**
- **Game compatibility database**

### 3. Smart Configuration
- **GPU-optimized profiles**
- **Game-specific tweaks**
- **Resolution-aware settings**
- **Performance vs Quality presets**

### 4. Safety & Security
- **Checksum verification** for all binaries
- **Backup creation** before any modification
- **Rollback capability**
- **Sandboxed testing** option
- **No root/sudo required**

### 5. User Experience
- **Interactive TUI** (Text User Interface)
- **CLI for automation**
- **Progress indicators**
- **Detailed logging**
- **Helpful error messages**

## 🔧 Technical Stack

### Languages & Tools
- **Shell (Bash 4+)**: Core scripting
- **Python 3.8+**: Optional advanced features
- **YAML**: Configuration files
- **Git LFS**: Binary storage
- **GitHub Actions**: CI/CD

### Dependencies (minimal)
- `bash` >= 4.0
- `lspci` (for GPU detection)
- `sed`, `awk`, `grep` (text processing)
- `curl` or `wget` (for updates)
- Optional: `jq` (JSON parsing)
- Optional: `dialog` (TUI)

## 📋 Installation Flow

```
┌─────────────────────────────────────────┐
│  User runs: bash install.sh            │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  1. System Requirements Check           │
│     - Bash version                      │
│     - Required tools                    │
│     - Disk space                        │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  2. GPU Detection                       │
│     - Vendor: AMD/Intel/NVIDIA          │
│     - Architecture: RDNA3, Arc, etc.    │
│     - Capabilities: AL2, XeSS, etc.     │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  3. Game Discovery                      │
│     - Scan Steam library                │
│     - Scan Lutris                       │
│     - User can add manually             │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  4. Game Selection (Interactive)        │
│     [x] Cyberpunk 2077                  │
│     [ ] Starfield                       │
│     [x] New World                       │
│     [ ] Red Dead Redemption 2           │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  5. Profile Selection                   │
│     ○ Maximum Quality (DLSS inputs)     │
│     ● Balanced (recommended)            │
│     ○ Maximum Performance (FSR direct)  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  6. Configuration Generation            │
│     - Merge GPU profile + Game profile  │
│     - Apply user preferences            │
│     - Generate OptiScaler.ini           │
│     - Generate fakenvapi.ini (if AMD)   │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  7. Backup & Installation               │
│     - Backup existing files             │
│     - Copy binaries                     │
│     - Install configurations            │
│     - Set permissions                   │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  8. Post-Install Configuration          │
│     - Generate Steam launch options     │
│     - Show user instructions            │
│     - Optionally apply to Steam         │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  9. Validation                          │
│     - Verify file installation          │
│     - Check permissions                 │
│     - Test configuration validity       │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  ✓ Installation Complete                │
│     - Summary report                    │
│     - Next steps guide                  │
│     - Troubleshooting links             │
└─────────────────────────────────────────┘
```

## 🎨 GPU Profile System

### Profile Structure (YAML)

```yaml
# profiles/gpu/amd-rdna3.yaml
metadata:
  name: "AMD RDNA3"
  description: "Optimized for AMD Radeon RX 7000 series"
  author: "OptiScaler Universal Team"
  version: "1.0.0"
  supported_gpus:
    - "Radeon RX 7900 XTX"
    - "Radeon RX 7900 XT"
    - "Radeon RX 7800 XT"
    - "Radeon RX 7700 XT"
    - "Radeon RX 7600"

capabilities:
  anti_lag_2: true
  fsr4_native: false
  fsr4_compatible: true
  xess_support: true
  dlss_inputs_recommended: true

optiscaler:
  upscalers:
    dx12: "fsr31"
    dx11: "fsr31_12"
    vulkan: "fsr31"
  
  fsr:
    fsr4_update: false  # Performance overhead on non-RDNA4
    non_linear_srgb: true
    velocity_factor: 1.0
    
  inputs:
    enable_dlss_inputs: true  # Better quality
    enable_fsr2_inputs: true
    enable_fsr3_inputs: true
    
  sharpness:
    override: true
    value: 0.4
    cas_enabled: true
    motion_sharpness: 0.5
    
  spoofing:
    streamline_spoofing: true
    dxgi_spoofing: true
    spoofed_vendor_id: "0x10de"  # NVIDIA
    spoofed_device_id: "0x2684"  # RTX 4090
    
  nvapi:
    override_dll: true
    
fakenvapi:
  enabled: true
  force_reflex: 2
  latencyflex_mode: 2

performance:
  expected_fps_gain: "50-70%"
  expected_latency_reduction: "30-40%"
  quality_rating: "9/10"

recommendations:
  ingame_upscaling: "DLSS Quality"
  ingame_reflex: "On + Boost"
  vsync: false
  quality_preset: "Ultra"
```

## 🎮 Game Profile System

```yaml
# profiles/games/cyberpunk2077.yaml
metadata:
  name: "Cyberpunk 2077"
  engine: "RED Engine 4"
  api: "DX12"
  dlss_version: "3.5"
  steamid: "1091500"
  
paths:
  steam_linux: "~/.local/share/Steam/steamapps/common/Cyberpunk 2077"
  proton_prefix: "~/.local/share/Steam/steamapps/compatdata/1091500"
  executable: "bin/x64/Cyberpunk2077.exe"
  config_dir: "bin/x64"

compatibility:
  optiscaler_status: "Excellent"
  known_issues: []
  tested_proton: ["GE-Proton 9-11", "Proton-EM 10.0-30"]
  
steam:
  launch_options: "WINEDLLOVERRIDES=dxgi.dll=n,b PROTON_FSR4_UPGRADE=1 %command%"
  recommended_proton: "Proton-EM 10.0-30"
  
specific_tweaks:
  # Game-specific OptiScaler overrides
  sharpness_override: 0.3  # Cyberpunk is already sharp
  motion_sharpness_enabled: false  # Can cause artifacts
  
  # DLSS-specific
  render_preset_quality: 0  # Default preset works best
  
performance_notes: |
  Cyberpunk 2077 benefits greatly from DLSS inputs with FSR4.
  Expect 60-80% FPS improvement with Quality preset.
  Anti-Lag 2 reduces input latency significantly in combat.

user_guide: |
  1. Set In-Game Graphics to DLSS Quality or Balanced
  2. Enable Ray Tracing for best visual quality
  3. Set NVIDIA Reflex to "On + Boost"
  4. Disable in-game sharpening (OptiScaler handles it)
```

## 🔍 Detection System

### GPU Detection Algorithm

```bash
# Pseudo-code
function detect_gpu() {
    # 1. Query hardware
    gpu_info = lspci | grep VGA
    
    # 2. Determine vendor
    if contains(gpu_info, "AMD|Radeon"):
        vendor = "AMD"
        detect_amd_generation()
    elif contains(gpu_info, "Intel|Arc"):
        vendor = "Intel"
        detect_intel_generation()
    elif contains(gpu_info, "NVIDIA"):
        vendor = "NVIDIA"
        detect_nvidia_generation()
    
    # 3. Check driver
    if vendor == "AMD" or vendor == "Intel":
        mesa_version = get_mesa_version()
        validate_mesa_compatibility()
    elif vendor == "NVIDIA":
        nvidia_driver = get_nvidia_driver()
        validate_nvidia_compatibility()
    
    # 4. Check capabilities
    capabilities = {
        "anti_lag_2": check_anti_lag_support(),
        "fsr4": check_fsr4_support(),
        "xess": check_xess_support(),
        "dlss": vendor == "NVIDIA"
    }
    
    # 5. Load appropriate profile
    profile = load_gpu_profile(vendor, generation)
    
    return {
        "vendor": vendor,
        "generation": generation,
        "capabilities": capabilities,
        "profile": profile
    }
}
```

### Game Detection Algorithm

```bash
function discover_games() {
    games = []
    
    # Steam library
    steam_libs = find_steam_libraries()
    for lib in steam_libs:
        manifests = find_app_manifests(lib)
        for manifest in manifests:
            game_info = parse_manifest(manifest)
            if is_supported_game(game_info):
                games.append(game_info)
    
    # Lutris
    lutris_games = query_lutris_database()
    games.extend(lutris_games)
    
    # Heroic
    heroic_games = scan_heroic_config()
    games.extend(heroic_games)
    
    return games
}
```

## 🛡️ Security Features

### 1. Binary Verification
```bash
# All binaries include SHA256 checksums
verify_binary() {
    local file=$1
    local expected_hash=$(grep $file checksums.txt | cut -d' ' -f1)
    local actual_hash=$(sha256sum $file | cut -d' ' -f1)
    
    if [ "$expected_hash" != "$actual_hash" ]; then
        error "Checksum mismatch for $file"
        error "Expected: $expected_hash"
        error "Got: $actual_hash"
        exit 1
    fi
}
```

### 2. Backup System
```bash
# Automatic backup before any changes
backup_game_files() {
    local game_dir=$1
    local backup_dir="$HOME/.optiscaler-universal/backups/$(date +%Y%m%d_%H%M%S)"
    
    mkdir -p "$backup_dir"
    
    # Backup existing OptiScaler files if present
    if [ -f "$game_dir/Bin64/dxgi.dll" ]; then
        cp "$game_dir/Bin64/dxgi.dll" "$backup_dir/"
    fi
    
    # Create backup manifest
    cat > "$backup_dir/MANIFEST.txt" << EOF
Game: $(basename "$game_dir")
Date: $(date)
Files backed up:
$(ls -la "$backup_dir")
EOF
    
    echo "$backup_dir"
}
```

### 3. Rollback Capability
```bash
rollback_installation() {
    local backup_dir=$1
    local game_dir=$2
    
    echo "Rolling back to backup from $backup_dir"
    
    # Restore backed up files
    cp -r "$backup_dir"/* "$game_dir/Bin64/"
    
    echo "Rollback complete"
}
```

## 📊 Logging System

```bash
# lib/logging.sh
LOG_FILE="$HOME/.optiscaler-universal/install.log"

log_info() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $*" | tee -a "$LOG_FILE"
}

log_warn() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [WARN] $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $*" | tee -a "$LOG_FILE" >&2
}

log_debug() {
    if [ "$DEBUG" = "1" ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] [DEBUG] $*" | tee -a "$LOG_FILE"
    fi
}
```

## 🧪 Testing Strategy

### Unit Tests
- GPU detection logic
- Configuration parser
- Path resolution
- Backup/restore system

### Integration Tests
- Full installation flow
- Multiple games
- Different GPU vendors
- Rollback scenarios

### CI/CD Pipeline
```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run ShellCheck
        run: shellcheck scripts/*.sh core/*.sh

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: bash tests/run_all.sh
```

## 📦 Release Strategy

### Versioning (Semantic Versioning)
- `MAJOR.MINOR.PATCH`
- Example: `1.2.3`
  - MAJOR: Breaking changes
  - MINOR: New features
  - PATCH: Bug fixes

### Release Checklist
- [ ] All tests passing
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Binaries checksums verified
- [ ] Tagged in git
- [ ] GitHub release created
- [ ] Community announcement

## 🤝 Contributing Guidelines

### Code Style
- Use `shellcheck` for all scripts
- Follow Google Shell Style Guide
- 4-space indentation
- Meaningful variable names
- Comments for complex logic

### Pull Request Process
1. Fork the repository
2. Create feature branch
3. Make changes with tests
4. Run all tests locally
5. Submit PR with description
6. Address review feedback
7. Merge when approved

## 📈 Future Roadmap

### Delivered: Core Release (v0.1.0-alpha, 2025-10-25)
- ✅ Unified GPU detection across AMD, Intel, and NVIDIA (architecture-aware)
- ✅ Steam library scanning with profile-aware configuration generation
- ✅ 6 GPU profiles + 10 game profiles shipped with checksumed binaries
- ✅ Installer, updater, uninstaller, and diagnostics with safe backups
- ✅ CI, automated tests, and baseline documentation

### Next Up: Integration & UX (v0.2.0)
- [ ] Lutris integration (library scan + launch options)
- [ ] Heroic Games Launcher detection
- [ ] Interactive TUI flow for install/update (dialog/whiptail)
- [ ] Automated benchmarking (pre/post FPS capture)
- [ ] Update notification hook when new profiles or binaries ship
- [ ] Per-game user overrides layered on shipped profiles
- [ ] Expand game catalog to 25 titles (add esports + F2P staples)
- [ ] AUR package & release checklist (trigger when repo reaches 100+ stars)

### Community & Sharing (v0.3.0)
- [ ] Community profile sharing hub (import/export signed YAML)
- [ ] Profile validation pipeline (lint + checksum)
- [ ] Optional web dashboard for profile browsing
- [ ] Multi-language UX strings (start with English plus one additional locale)

### Distribution & Scale (v1.0.0)
- [ ] Flatpak/AppImage builds with automatic updates
- [ ] 100+ curated game profiles
- [ ] Professional documentation set and support portal
- [ ] Telemetry-free diagnostics bundle for bug reports

## 🌐 Community Engagement

### Platforms
- **GitHub**: Main repository
- **Discord**: Community chat
- **Reddit**: r/linux_gaming presence
- **ProtonDB**: Integration
- **Gaming on Linux**: News/updates

### Content Creation
- Installation guides
- Performance comparisons
- GPU-specific guides
- Video tutorials
- Blog posts

---

## 📝 License

MIT License - Open source, free to use, modify, and distribute.

## 👥 Team Structure

- **Core Maintainers**: 2-3 people
- **Contributors**: Open to all
- **Community Moderators**: 2-3 people
- **Testers**: Community volunteers

---

**Next Steps**: Focus on v0.2.0 deliverables—Lutris/Heroic integration, interactive TUI, expanded game catalog, and the AUR packaging gate.
