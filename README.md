<div align="center">
<img width="1024" height="1024" alt="banner" src="https://github.com/user-attachments/assets/b039142c-6f2f-4c71-bb63-a2c115b59941" />

# OptiScaler Universal

### Automated GPU Optimization for Linux Gaming

[![CI](https://img.shields.io/github/actions/workflow/status/ind4skylivey/0ptiscaler4linux/ci.yml?branch=main&style=flat-square&logo=github)](https://github.com/ind4skylivey/0ptiscaler4linux/actions)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0.0-0099ff.svg?style=flat-square)](https://github.com/ind4skylivey/0ptiscaler4linux/releases/tag/v2.0.0)
[![AUR](https://img.shields.io/badge/AUR-optiscaler--universal-1793d1.svg?style=flat-square&logo=arch-linux)](https://aur.archlinux.org/packages/optiscaler-universal)

</div>

---

Automated configuration tool for OptiScaler on Linux gaming systems.

Detects your GPU, scans your Steam library, and applies optimal upscaling settings (FSR4, XeSS, DLSS) automatically.

---

## Features

- **Automatic GPU detection** — AMD (RDNA1-4), Intel (Arc), NVIDIA (RTX)
- **Multi-disk Steam scanning** — Finds games across all mounted libraries
- **Profile-based configuration** — 6 GPU profiles, 10+ game profiles
- **Safe installation** — Automatic backups, one-command rollback
- **FSR 4.2.0 support** — Frame generation and adaptive quality

---

## Installation

### Arch Linux (AUR)

```bash
yay -S optiscaler-universal
# or
paru -S optiscaler-universal
```

After installation:
```bash
optiscaler-install
```

### Manual (Any Distro)

```bash
git clone https://github.com/ind4skylivey/0ptiscaler4linux.git
cd 0ptiscaler4linux
bash scripts/install.sh
```

---

## Requirements

- **Bash** 4.0+
- **pciutils** (for GPU detection)
- **wget** and **unzip** (for downloading dependencies)

Optional:
- `mesa-utils` — AMD/Intel GPU detection
- `git-lfs` — Download OptiScaler binaries
- `python3` — Advanced YAML parsing

---

## Usage

### Basic

```bash
# Interactive installation
bash scripts/install.sh

# Scan only (no changes)
bash scripts/install.sh --scan-only

# List supported games
bash scripts/install.sh --list-games
```

### Advanced

```bash
# Force fresh scan (ignore cache)
bash scripts/install.sh --force-rescan

# Verbose output
bash scripts/install.sh --verbose

# Debug mode
LOG_LEVEL=DEBUG bash scripts/install.sh --debug

# Custom game directory
bash scripts/install.sh --game-dir "/path/to/game"
```

### Steam Deck

See [Steam Deck Setup Guide](docs/steam-deck-setup-optiscaler-linux-gaming.md) for optimized installation.

---

## Supported Hardware

### GPUs

| Vendor | Architectures | Upscaling |
|--------|---------------|-----------|
| AMD | RDNA1, RDNA2, RDNA3, RDNA4 | FSR3.1, FSR4 |
| Intel | Arc, Integrated | XeSS |
| NVIDIA | RTX 20/30/40, GTX 16/10 | DLSS |

### Games

Tested with: Cyberpunk 2077, Starfield, Red Dead Redemption 2, Hogwarts Legacy, God of War, Spider-Man Remastered, Alan Wake 2, The Witcher 3, Elden Ring, New World.

See [Game Support](docs/GAME_SUPPORT.md) for full list.

---

## Documentation

- [Installation Guide](docs/INSTALLATION.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [GPU Profiles](docs/GPU_PROFILES.md)
- [Multi-Disk Detection](docs/multi-disk-detection.md)
- [Architecture](docs/architecture/PROJECT_DESIGN.md)

---

## Contributing

Contributions welcome: bug reports, game profiles, GPU optimizations, documentation.

See [Contributing Guide](CONTRIBUTING.md) for guidelines.

---

## License

MIT License — see [LICENSE](LICENSE)

### Third-Party

- [OptiScaler](https://github.com/optiscaler/OptiScaler) — GPL-3.0
- [fakenvapi](https://github.com/FakeMichau/fakenvapi) — MIT
- AMD FidelityFX SDK — MIT

---

## Disclaimer

Unofficial tool. Not affiliated with AMD, Intel, NVIDIA, Valve, or game developers. Use at your own risk.
