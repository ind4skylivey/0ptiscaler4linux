#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  AUR Publishing Commands - Copy & Paste Guide
# ═══════════════════════════════════════════════════════════════════════════
#
#  Run these commands AFTER creating GitHub release v0.1.0
#
# ═══════════════════════════════════════════════════════════════════════════

echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                           ║"
echo "║                     AUR PUBLISHING GUIDE                                 ║"
echo "║                                                                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "PREREQUISITES:"
echo "✅ GitHub Release v0.1.0 published"
echo "✅ SSH key added to AUR account"
echo "✅ makepkg installed (Arch/Manjaro only)"
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""

# ═══════════════════════════════════════════════════════════════════════════
#  STEP 1: Get SHA256 Hash
# ═══════════════════════════════════════════════════════════════════════════

echo "STEP 1: Get SHA256 Hash"
echo "─────────────────────────"
echo ""
echo "# Download the release tarball"
echo "cd /tmp"
echo "wget https://github.com/ind4skylivey/0ptiscaler4linux/archive/v0.1.0.tar.gz"
echo ""
echo "# Calculate hash"
echo "sha256sum v0.1.0.tar.gz"
echo ""
echo "# Copy the hash (first part before the space)"
echo "# Example output: abc123def456... v0.1.0.tar.gz"
echo "#                 ^^^^^^^^^^^^^^^ Copy this"
echo ""
read -p "Press Enter when you have the hash..."
echo ""

# ═══════════════════════════════════════════════════════════════════════════
#  STEP 2: Update PKGBUILD
# ═══════════════════════════════════════════════════════════════════════════

echo "STEP 2: Update PKGBUILD"
echo "───────────────────────"
echo ""
echo "# Edit PKGBUILD"
echo "cd /home/il1v3y/optiscaler-universal"
echo "nano PKGBUILD"
echo ""
echo "Change these lines:"
echo "1. Maintainer info:"
echo "   # Maintainer: Your Name <your.email@example.com>"
echo "   TO:"
echo "   # Maintainer: YourRealName <your.real@email.com>"
echo ""
echo "2. SHA256 hash:"
echo "   sha256sums=('SKIP')"
echo "   TO:"
echo "   sha256sums=('YOUR_HASH_HERE')"
echo ""
echo "Save and exit (Ctrl+X, Y, Enter)"
echo ""
read -p "Press Enter when PKGBUILD is updated..."
echo ""

# ═══════════════════════════════════════════════════════════════════════════
#  STEP 3: Generate .SRCINFO
# ═══════════════════════════════════════════════════════════════════════════

echo "STEP 3: Generate .SRCINFO"
echo "─────────────────────────"
echo ""
echo "If you have makepkg (Arch/Manjaro):"
echo "cd /home/il1v3y/optiscaler-universal"
echo "makepkg --printsrcinfo > .SRCINFO"
echo ""
echo "If you DON'T have makepkg:"
echo "nano .SRCINFO"
echo "# Manually update:"
echo "# - pkgver = 0.1.0"
echo "# - sha256sums = YOUR_HASH"
echo ""
read -p "Press Enter when .SRCINFO is updated..."
echo ""

# ═══════════════════════════════════════════════════════════════════════════
#  STEP 4: Test Build (Optional)
# ═══════════════════════════════════════════════════════════════════════════

echo "STEP 4: Test Build (OPTIONAL - Only if you have Arch/Manjaro)"
echo "──────────────────────────────────────────────────────────────"
echo ""
echo "cd /home/il1v3y/optiscaler-universal"
echo "makepkg -si"
echo ""
echo "Test commands:"
echo "optiscaler-install --help"
echo "optiscaler-diagnose --verbose"
echo ""
echo "If it works, remove:"
echo "sudo pacman -R optiscaler-universal"
echo ""
echo "Skip this step if you don't have Arch/Manjaro"
echo ""
read -p "Press Enter to continue..."
echo ""

# ═══════════════════════════════════════════════════════════════════════════
#  STEP 5: Clone AUR Repository
# ═══════════════════════════════════════════════════════════════════════════

echo "STEP 5: Clone AUR Repository"
echo "────────────────────────────"
echo ""
echo "# Clone your AUR repo (empty at first)"
echo "cd ~"
echo "git clone ssh://aur@aur.archlinux.org/optiscaler-universal.git aur-optiscaler"
echo "cd aur-optiscaler"
echo ""
echo "Expected output:"
echo "Cloning into 'aur-optiscaler'..."
echo "warning: You appear to have cloned an empty repository."
echo "^ This is NORMAL for new AUR packages!"
echo ""
read -p "Press Enter after cloning..."
echo ""

# ═══════════════════════════════════════════════════════════════════════════
#  STEP 6: Copy Files
# ═══════════════════════════════════════════════════════════════════════════

echo "STEP 6: Copy Files to AUR Repo"
echo "───────────────────────────────"
echo ""
echo "cd ~/aur-optiscaler"
echo "cp /home/il1v3y/optiscaler-universal/PKGBUILD ."
echo "cp /home/il1v3y/optiscaler-universal/.SRCINFO ."
echo ""
echo "# Create install message (optional but nice)"
echo "cat > optiscaler-universal.install << 'EOFINSTALL'"
echo "post_install() {"
echo "    echo \"\""
echo "    echo \"╔═══════════════════════════════════════════════════════════════╗\""
echo "    echo \"║  OptiScaler Universal installed successfully!                ║\""
echo "    echo \"╚═══════════════════════════════════════════════════════════════╝\""
echo "    echo \"\""
echo "    echo \"Commands available:\""
echo "    echo \"  optiscaler-install    - Configure OptiScaler\""
echo "    echo \"  optiscaler-uninstall  - Remove installations\""
echo "    echo \"  optiscaler-update     - Update tool\""
echo "    echo \"  optiscaler-diagnose   - Diagnose issues\""
echo "    echo \"\""
echo "    echo \"Quick start: optiscaler-install\""
echo "    echo \"\""
echo "}"
echo ""
echo "post_upgrade() {"
echo "    post_install"
echo "}"
echo "EOFINSTALL"
echo ""
echo "# Verify files"
echo "ls -la"
echo ""
read -p "Press Enter after copying files..."
echo ""

# ═══════════════════════════════════════════════════════════════════════════
#  STEP 7: Commit and Push to AUR
# ═══════════════════════════════════════════════════════════════════════════

echo "STEP 7: Commit and Push to AUR"
echo "───────────────────────────────"
echo ""
echo "cd ~/aur-optiscaler"
echo ""
echo "# Add files"
echo "git add PKGBUILD .SRCINFO optiscaler-universal.install"
echo ""
echo "# Commit"
echo "git commit -m \"Initial import: optiscaler-universal 0.1.0-alpha"
echo ""
echo "Intelligent OptiScaler configuration tool for Linux gaming."
echo "Automatically detects GPU and applies optimal settings."
echo ""
echo "Features:"
echo "- Automatic GPU detection (AMD/Intel/NVIDIA)"
echo "- 10 pre-configured game profiles"
echo "- Steam library integration"
echo "- Automatic backups and safety features"
echo ""
echo "Project: https://github.com/ind4skylivey/0ptiscaler4linux\""
echo ""
echo "# Push to AUR"
echo "git push origin master"
echo ""
read -p "Press Enter after pushing..."
echo ""

# ═══════════════════════════════════════════════════════════════════════════
#  STEP 8: Verify
# ═══════════════════════════════════════════════════════════════════════════

echo "STEP 8: Verify on AUR"
echo "────────────────────"
echo ""
echo "✅ Go to: https://aur.archlinux.org/packages/optiscaler-universal"
echo ""
echo "You should see:"
echo "- Package information"
echo "- PKGBUILD visible"
echo "- Installation command"
echo ""
echo "Test installation (if you have Arch):"
echo "yay -S optiscaler-universal"
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "🎉 CONGRATULATIONS! Your package is now on AUR!"
echo ""
echo "Next steps:"
echo "1. Update README with AUR installation method"
echo "2. Announce on r/archlinux and r/linux_gaming"
echo "3. Monitor AUR comments for feedback"
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
