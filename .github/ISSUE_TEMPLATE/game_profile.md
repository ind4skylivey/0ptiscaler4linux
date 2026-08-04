---
name: Game Profile Contribution
about: Submit a new game profile or update an existing one
title: '[GAME] '
labels: game-profile, needs-triage
assignees: ''
---

<!--
  ┌─────────────────────────────────────────────────────────────────┐
  │  READ BEFORE SUBMITTING                                         │
  │                                                                 │
  │  Game profiles MUST be tested on real hardware. Profiles        │
  │  without verification data will be rejected.                    │
  │                                                                 │
  │  Check existing profiles first:                                 │
  │  https://github.com/ind4skylivey/0ptiscaler4linux/tree/main/profiles │
  └─────────────────────────────────────────────────────────────────┘
-->

## Pre-Submission Checklist

- [ ] I have searched [existing profiles](https://github.com/ind4skylivey/0ptiscaler4linux/tree/main/profiles) and confirmed this game does NOT already have a profile
- [ ] I have tested this game with OptiScaler Universal on **real hardware** (not theoretical or from someone else's report)
- [ ] I have verified the Steam App ID on [SteamDB](https://steamdb.info/) or the correct store page
- [ ] I understand that profiles without actual test data will be rejected

## Game Information

| Field | Value |
|-------|-------|
| **Game Name** | |
| **Steam App ID** | <!-- from SteamDB URL, e.g., 1245620 for Elden Ring --> |
| **Store** | <!-- Steam / GOG / Epic / Other --> |
| **Graphics API** | <!-- DX11 / DX12 / Vulkan / OpenGL --> |
| **Engine** | <!-- e.g., Unreal Engine 5, Unity, RE Engine --> |

## Test Environment

**ALL fields are REQUIRED.**

| Field | Value |
|-------|-------|
| **GPU** | <!-- e.g., AMD Radeon RX 7900 XTX --> |
| **GPU Driver** | <!-- e.g., Mesa 25.2.0 --> |
| **Distribution** | <!-- e.g., Arch Linux --> |
| **Wine/Proton Version** | <!-- e.g., Proton 9.0-4 --> |
| **OptiScaler Version** | <!-- version or git commit --> |

## Testing Results

| Metric | Value |
|--------|-------|
| **Compatibility** | <!-- Excellent / Good / Partial / Broken --> |
| **Upscaler Used** | <!-- FSR2 / FSR3 / XeSS / DLSS-to-FSR --> |
| **FPS without OptiScaler** | |
| **FPS with OptiScaler** | |
| **FPS Improvement** | <!-- percentage or "N/A" --> |
| **Visual Quality** | <!-- Excellent / Good / Noticeable artifacts / Poor --> |

## Game-Specific Notes

<!-- Installation quirks, required launch options, known issues, recommended settings. -->


## Profile File

<!-- Paste the YAML profile content below, or attach the file. -->

```yaml
# PASTE YOUR YAML PROFILE HERE
```

## Screenshots / Evidence

<!-- Optional but helpful: before/after screenshots, FPS overlay captures, etc. -->
