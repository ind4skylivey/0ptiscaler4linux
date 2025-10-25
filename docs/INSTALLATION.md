# OptiScaler Universal - Installation Guide

## Quick Start (5 minutes)

### 1. Clone Repository
```bash
git clone https://github.com/ind4skylivey/0ptiscaler4linux.git
cd 0ptiscaler4linux
```

### 2. Run Installer
```bash
bash scripts/install.sh
```

The installer will:
- ✓ Detect your GPU automatically
- ✓ Scan Steam library for supported games
- ✓ Generate optimized configuration files

### 3. Copy Configuration
```bash
# Copy generated configs to your game
cp ~/.optiscaler-universal/generated/*.ini "$GAME_DIR/Bin64/"
```

### 4. Configure Steam
Right-click game → Properties → Launch Options:
```
WINEDLLOVERRIDES=dxgi.dll=n,b PROTON_FSR4_UPGRADE=1 %command%
```

Select Proton: **Proton-EM 10.0-30** (or GE-Proton 10-21+)

### 5. In-Game Settings
- Upscaling: **DLSS Quality**
- NVIDIA Reflex: **On + Boost**
- VSync: **Off**

### 6. Verify
Press **HOME** in-game → OptiScaler menu should appear

## Supported Games
- Cyberpunk 2077
- New World
- Starfield
- Red Dead Redemption 2
- Spider-Man Remastered
- God of War
- Alan Wake 2
- Hogwarts Legacy
- The Witcher 3
- Elden Ring

## Troubleshooting
- **No DLSS option**: Check Steam launch options
- **Low FPS**: Verify correct GPU profile loaded
- **Crashes**: Try different Proton version

For more help: https://github.com/ind4skylivey/0ptiscaler4linux/issues
