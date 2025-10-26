# Game Support List

## Fully Tested Games (10)

| Game | Status | API | Steam ID | Notes |
|------|--------|-----|----------|-------|
| Cyberpunk 2077 | ✅ Excellent | DX12 | 1091500 | Full RT support |
| New World | ✅ Excellent | DX12 | 1063730 | Great with FSR3.1 |
| Starfield | ✅ Good | DX12 | 1716740 | Minor tweaks needed |
| Red Dead Redemption 2 | ✅ Good | DX12/Vulkan | 1174180 | Use Vulkan API |
| Spider-Man Remastered | ✅ Excellent | DX12 | 1817070 | Perfect compatibility |
| God of War | ✅ Excellent | DX11 | 1593500 | FSR3.1 via DX12 wrapper |
| Alan Wake 2 | ✅ Excellent | DX12 | 1547180 | Heavy RT, great with FSR |
| Hogwarts Legacy | ✅ Good | DX12 | 990080 | Some shader compilation |
| The Witcher 3 | ✅ Excellent | DX11/DX12 | 292030 | Both APIs work |
| Elden Ring | ✅ Good | DX12 | 1245620 | FSR helps with performance |

## Status Legend
- ✅ Excellent: Works perfectly, tested thoroughly
- ✅ Good: Works well, minor issues
- ⚠️ Partial: Works but with limitations
- ❌ Broken: Known issues

## Adding New Games

1. Test game with OptiScaler
2. Create profile: `cp profiles/games/generic.yaml profiles/games/yourgame.yaml`
3. Fill in details (Steam ID, paths, tweaks)
4. Test thoroughly
5. Submit PR!

See CONTRIBUTING.md for detailed instructions.

## Compatibility Notes

**Best Results**: DX12 games with DLSS support
**Good Results**: DX11 games (via FSR3.1_12 wrapper)
**Mixed Results**: Vulkan games (varies by engine)

## Reporting Compatibility

Found a working game? Open an issue or PR with:
- Game name and Steam ID
- OptiScaler version tested
- GPU used
- Performance notes
- Any special configuration needed
