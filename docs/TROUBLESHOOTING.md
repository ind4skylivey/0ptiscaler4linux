# Troubleshooting Guide

Run diagnostics first: `bash scripts/diagnose.sh --verbose`

## Common Issues

### GPU Not Detected
Install pciutils: `sudo pacman -S pciutils` or `sudo apt install pciutils`

### OptiScaler Not Loading
1. Check Steam Launch Options: `WINEDLLOVERRIDES="dxgi.dll=n,b" PROTON_FSR4_UPGRADE=1 %command%`
2. Verify files: `ls /path/to/game/dxgi.dll OptiScaler.ini`
3. Check logs: `cat /path/to/game/OptiScaler.log`

### Poor Performance
1. RDNA3: Disable FSR4 in OptiScaler.ini: `Fsr4Update = false`
2. Update drivers: Mesa 25.2.0+ or NVIDIA 550+
3. Check GPU profile matches your hardware

### Anti-Lag 2 Not Working (AMD)
1. Add nvapi override: `WINEDLLOVERRIDES="dxgi.dll=n,b;nvapi64.dll=n,b"`
2. Enable Reflex in-game settings
3. Check fakenvapi.ini: `ForceReflex = 2`

### Flickering/Artifacts
Reduce motion sharpness in OptiScaler.ini: `MotionSharpnessEnabled = false`

## Getting Help
Open issue with diagnostics: https://github.com/ind4skylivey/0ptiscaler4linux/issues
