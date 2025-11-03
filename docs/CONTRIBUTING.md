# Contributing to OptiScaler Universal

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to the project.

## 🌟 Ways to Contribute

- 🐛 **Report bugs** - Help us identify and fix issues
- ✨ **Suggest features** - Share ideas for improvements
- 📝 **Improve documentation** - Help make docs clearer
- 🎮 **Add game profiles** - Contribute profiles for new games
- 🖥️ **Optimize GPU profiles** - Share better configurations
- 🧪 **Test and provide feedback** - Try on different systems
- 💻 **Submit code** - Fix bugs or implement features

## 📋 Before You Start

1. Check [existing issues](https://github.com/ind4skylivey/0ptiscaler4linux/issues) to avoid duplicates
2. Read the [PROJECT_DESIGN.md](../PROJECT_DESIGN.md) to understand architecture
3. Test on your system first
4. Follow the code style guidelines below

## 🐛 Reporting Bugs

### Good Bug Report Includes:

- **Clear title**: Descriptive summary of the issue
- **System info**: GPU, driver version, distribution
- **Steps to reproduce**: Detailed steps to trigger the bug
- **Expected vs actual behavior**: What should happen vs what happens
- **Logs**: Relevant error messages or log files
- **Screenshots/videos**: If applicable

### Template:

```markdown
**System Information:**
- GPU: AMD Radeon RX 7900 XTX
- Driver: Mesa 25.2.0
- Distribution: Arch Linux
- Kernel: 6.8.5

**Bug Description:**
OptiScaler fails to load in Cyberpunk 2077

**Steps to Reproduce:**
1. Run install.sh
2. Launch Cyberpunk 2077 via Steam
3. No upscaling applied, native resolution only

**Expected Behavior:**
OptiScaler should load and provide upscaling options

**Actual Behavior:**
Game runs at native resolution, OptiScaler.log shows error

**Logs:**
[Attach OptiScaler.log and relevant terminal output]

**Additional Context:**
Works fine on other games like New World
```

## ✨ Suggesting Features

### Good Feature Request Includes:

- **Use case**: Why is this feature needed?
- **Proposed solution**: How should it work?
- **Alternatives**: Other ways to achieve the goal
- **Implementation ideas**: Technical approach (if you have one)

## 🎮 Contributing Game Profiles

Game profiles are one of the easiest ways to contribute!

### Creating a New Game Profile

1. **Test the game** with OptiScaler
2. **Copy template**:
   ```bash
   cp profiles/games/generic.yaml profiles/games/your-game.yaml
   ```

3. **Fill in metadata**:
   ```yaml
   metadata:
     name: "Your Game Name"
     engine: "Unreal Engine 5"  # or Unity, RED Engine, etc.
     api: "DX12"  # or DX11, Vulkan
     dlss_version: "3.5"  # if supported
     steamid: "123456"  # from SteamDB
   ```

4. **Add paths**:
   ```yaml
   paths:
     steam_linux: "~/.local/share/Steam/steamapps/common/YourGame"
     executable: "Binaries/Win64/YourGame.exe"
     config_dir: "Binaries/Win64"
   ```

5. **Test compatibility**:
   - Install OptiScaler in the game
   - Test different upscaling modes
   - Document any issues or special requirements

6. **Add game-specific tweaks**:
   ```yaml
   game_specific_tweaks:
     sharpness_override: 0.4
     motion_sharpness_enabled: true
   ```

7. **Submit PR** with your profile!

### Game Profile Checklist

- [ ] Tested on real hardware
- [ ] Steam ID verified on [SteamDB](https://steamdb.info/)
- [ ] Paths confirmed (install location, executable, config directory)
- [ ] Documented any known issues
- [ ] Added recommended settings
- [ ] Tested with recommended GPU profile

## 🖥️ Contributing GPU Profiles

### Optimizing Existing Profiles

If you find better settings for your GPU:

1. **Test thoroughly** - Multiple games, different scenarios
2. **Document results** - FPS gains, quality, issues
3. **Compare with defaults** - Ensure it's actually better
4. **Submit PR** with benchmarks/evidence

### Adding New GPU Generation

1. Study existing profiles in `profiles/gpu/`
2. Research GPU capabilities (FSR4, Anti-Lag 2, etc.)
3. Test extensively on real hardware
4. Document driver requirements
5. Add to detector logic in `core/detector.sh`

## 💻 Code Contributions

### Setting Up Development Environment

```bash
# Clone repository
git clone https://github.com/ind4skylivey/0ptiscaler4linux.git
cd 0ptiscaler4linux

# Install development tools
sudo pacman -S shellcheck git-lfs  # Arch
sudo apt install shellcheck git-lfs  # Debian/Ubuntu

# Setup Git LFS
git lfs install
git lfs pull

# Test existing functionality
bash scripts/diagnose.sh --verbose
```

### Code Style Guidelines

#### Shell Scripts

- **Use Bash 4+** features
- **Follow** [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- **4-space indentation** (no tabs)
- **Meaningful names** for variables and functions
- **Comment complex logic**
- **Run shellcheck** on all scripts

#### Good Example:

```bash
#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  Function description
# ═══════════════════════════════════════════════════════════════════════════

detect_gpu_vendor() {
    local gpu_info="$1"
    
    if echo "$gpu_info" | grep -iq "amd\|radeon"; then
        echo "AMD"
        return 0
    elif echo "$gpu_info" | grep -iq "intel"; then
        echo "Intel"
        return 0
    else
        echo "Unknown"
        return 1
    fi
}

# Usage
GPU_VENDOR=$(detect_gpu_vendor "$(lspci | grep VGA)")
```

#### YAML Profiles

- **Consistent indentation** (2 spaces)
- **Meaningful keys**
- **Comments for complex settings**
- **Follow existing structure**

### Testing Your Changes

```bash
# Run shellcheck on modified scripts
shellcheck core/*.sh lib/*.sh scripts/*.sh

# Test detector
source core/detector.sh && detect_gpu

# Test game scanner
source core/game-scanner.sh && scan_steam_games

# Run diagnostics
bash scripts/diagnose.sh --verbose

# Test full installation flow
bash scripts/install.sh
```

### Commit Message Guidelines

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**

```bash
feat(profiles): add Baldur's Gate 3 game profile

- Added complete game profile with Steam paths
- Tested on AMD RDNA3 and NVIDIA RTX 4000
- Includes Vulkan API specific tweaks

Closes #42
```

```bash
fix(detector): improve AMD RDNA4 detection

- Fixed regex pattern for RX 9000 series
- Added Navi 4 architecture detection
- Updated driver requirements

Fixes #55
```

### Pull Request Process

1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feat/your-feature`
3. **Make changes** following style guidelines
4. **Test thoroughly**
5. **Commit** with clear messages
6. **Push** to your fork
7. **Open PR** with description

#### PR Description Template:

```markdown
## Description
Clear description of what this PR does

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Game profile
- [ ] GPU profile optimization

## Testing
- [ ] Tested on real hardware
- [ ] Ran shellcheck
- [ ] No new errors in logs
- [ ] Verified with diagnose.sh

## System Tested On
- GPU: AMD Radeon RX 7900 XTX
- Driver: Mesa 25.2.0
- Distribution: Arch Linux

## Screenshots/Logs
[If applicable]

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-reviewed the code
- [ ] Commented complex sections
- [ ] Updated documentation
- [ ] No breaking changes (or documented)
```

## 🧪 Testing Guidelines

### Manual Testing Checklist

- [ ] GPU detection works for your hardware
- [ ] Game scanning finds your installed games
- [ ] Configuration generation completes without errors
- [ ] Generated configs are valid
- [ ] Logs are clear and helpful
- [ ] No crashes or hangs

### Automated Testing (Future)

We're working on adding automated tests. Check `tests/` directory.

## 📖 Documentation Contributions

### Improving Existing Docs

- Fix typos, grammar, clarity
- Add missing information
- Update outdated content
- Add examples

### Adding New Docs

- Follow existing structure
- Use clear headings
- Include code examples
- Add table of contents for long docs

## 🤝 Community Guidelines

### Code of Conduct

- **Be respectful** - Treat others with kindness
- **Be constructive** - Provide helpful feedback
- **Be patient** - Remember people have different skill levels
- **Be collaborative** - We're all here to improve Linux gaming

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and ideas
- **Pull Requests**: Code and content contributions

## 🎓 Learning Resources

### Shell Scripting
- [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/)
- [ShellCheck Wiki](https://www.shellcheck.net/wiki/)

### OptiScaler/Gaming
- [OptiScaler Documentation](https://github.com/optiscaler/OptiScaler)
- [ProtonDB](https://www.protondb.com/)
- [r/linux_gaming](https://www.reddit.com/r/linux_gaming/)

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 🙏 Recognition

Contributors will be:
- Listed in project documentation
- Credited in release notes
- Appreciated by the Linux gaming community!

---

**Questions?** Open a [GitHub Discussion](https://github.com/ind4skylivey/0ptiscaler4linux/discussions)

**Ready to contribute?** Check our [good first issue](https://github.com/ind4skylivey/0ptiscaler4linux/labels/good%20first%20issue) label!
