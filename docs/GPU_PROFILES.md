# GPU Profiles Guide

## Supported GPUs

### AMD RDNA4 (RX 9000 series)
- **Profile**: `amd-rdna4.yaml`
- **FSR4**: Native support with full hardware acceleration
- **Anti-Lag 2**: Yes
- **Expected Gain**: 60-80% FPS, 40-50% latency reduction
- **Recommended**: FSR4 upscaler, Quality preset

### AMD RDNA3 (RX 7000 series)
- **Profile**: `amd-rdna3.yaml`
- **FSR4**: Compatible but with overhead (use FSR3.1 instead)
- **Anti-Lag 2**: Yes
- **Expected Gain**: 50-70% FPS, 30-40% latency reduction
- **Recommended**: FSR3.1 upscaler, DLSS inputs enabled

### AMD RDNA2 (RX 6000 series)
- **Profile**: `amd-rdna2.yaml`
- **FSR3.1**: Excellent performance
- **Anti-Lag 2**: Yes
- **Expected Gain**: 55-75% FPS, 35-45% latency reduction

### AMD RDNA1 (RX 5000 series)
- **Profile**: `amd-rdna1.yaml`
- **FSR3.1**: Good performance
- **Anti-Lag 2**: Yes
- **Expected Gain**: 40-60% FPS, 25-35% latency reduction

### Intel Arc (A-series)
- **Profile**: `intel-arc.yaml`
- **XeSS**: Native support
- **Expected Gain**: 40-60% FPS
- **Recommended**: XeSS upscaler for best quality

### NVIDIA RTX
- **Profile**: `nvidia-rtx.yaml`
- **DLSS**: Native (OptiScaler optional)
- **Reflex**: Native
- **Note**: OptiScaler mainly useful for additional features

## Profile Selection

Automatic detection:
```bash
bash scripts/install.sh  # Auto-detects GPU
```

Manual selection:
```bash
bash scripts/install.sh --gpu-profile profiles/gpu/amd-rdna3.yaml
```

## Customizing Profiles

Copy and modify:
```bash
cp profiles/gpu/amd-rdna3.yaml profiles/gpu/custom.yaml
# Edit custom.yaml
bash scripts/install.sh --gpu-profile profiles/gpu/custom.yaml
```

See CONTRIBUTING.md for profile format details.
