# ✅ AUR Submission Checklist

**Status:** Ready to submit after GitHub release

---

## 📋 Pre-requisites (Already Done!)

- ✅ AUR account created
- ✅ PKGBUILD files created
- ✅ Documentation ready

---

## 🚀 Steps to Submit to AUR

### Step 1: Create GitHub Release (5 minutes)

**On your local machine:**

```bash
cd /home/il1v3y/optiscaler-universal

# Create and push tag
git tag -a v0.1.0 -m "Release v0.1.0-alpha - First public release"
git push origin v0.1.0
```

**Then on GitHub web:**
1. Go to: https://github.com/ind4skylivey/0ptiscaler4linux/releases/new
2. Choose tag: `v0.1.0`
3. Release title: `v0.1.0-alpha - First Alpha Release`
4. Description: Copy from `ANNOUNCEMENT.md`
5. Click **"Publish release"**

---

### Step 2: Get SHA256 Hash (2 minutes)

```bash
# Download the release tarball
cd /tmp
wget https://github.com/ind4skylivey/0ptiscaler4linux/archive/v0.1.0.tar.gz

# Get the hash
sha256sum v0.1.0.tar.gz

# OUTPUT WILL LOOK LIKE:
# abc123def456... v0.1.0.tar.gz
# ^^^^^^^^^^^^^^^ Copy this hash
```

---

### Step 3: Update PKGBUILD (2 minutes)

```bash
cd /home/il1v3y/optiscaler-universal

# Edit PKGBUILD
nano PKGBUILD

# Find this line:
sha256sums=('SKIP')

# Replace with:
sha256sums=('YOUR_HASH_FROM_STEP_2')

# Save and exit (Ctrl+X, Y, Enter)
```

---

### Step 4: Update Your Info (1 minute)

```bash
# Edit PKGBUILD header
nano PKGBUILD

# Change this line:
# Maintainer: Your Name <your.email@example.com>

# To:
# Maintainer: YourRealName <your.real@email.com>

# Save and exit
```

---

### Step 5: Test Build (Optional but Recommended)

**Only if you have Arch/Manjaro:**

```bash
cd /home/il1v3y/optiscaler-universal

# Install build tools if needed
sudo pacman -S base-devel namcap

# Test build
makepkg -si

# Validate
namcap PKGBUILD

# Test commands
optiscaler-install --help
optiscaler-diagnose --verbose

# If everything works, remove test install
sudo pacman -R optiscaler-universal
```

**If you don't have Arch:**
- Skip this step
- Ask a friend with Arch to test
- Or submit and wait for AUR users to report issues

---

### Step 6: Generate .SRCINFO (1 minute)

```bash
cd /home/il1v3y/optiscaler-universal

# Generate .SRCINFO
makepkg --printsrcinfo > .SRCINFO

# If you don't have makepkg, manually update .SRCINFO:
nano .SRCINFO

# Update these lines:
pkgver = 0.1.0
sha256sums = YOUR_HASH_FROM_STEP_2
```

---

### Step 7: Setup SSH for AUR (2 minutes)

```bash
# Check if you have SSH key
ls ~/.ssh/id_*.pub

# If not, create one:
ssh-keygen -t ed25519 -C "your.email@example.com"
# Press Enter for all prompts (use defaults)

# Copy your public key
cat ~/.ssh/id_ed25519.pub

# Go to AUR website:
# https://aur.archlinux.org/account/YourUsername/
# Paste the key in "SSH Public Key" section
# Click "Update"
```

---

### Step 8: Clone AUR Repository (2 minutes)

```bash
# Clone the AUR repo (creates empty repo)
cd ~
git clone ssh://aur@aur.archlinux.org/optiscaler-universal.git aur-optiscaler-universal

# Should show:
# Cloning into 'aur-optiscaler-universal'...
# warning: You appear to have cloned an empty repository.
# ^ This is normal for new AUR packages!

cd aur-optiscaler-universal
```

---

### Step 9: Copy Files to AUR Repo (1 minute)

```bash
# Copy PKGBUILD and .SRCINFO
cp /home/il1v3y/optiscaler-universal/PKGBUILD .
cp /home/il1v3y/optiscaler-universal/.SRCINFO .

# Optional: Create install message
cat > optiscaler-universal.install << 'EOF'
post_install() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║  OptiScaler Universal installed successfully!                ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Commands available:"
    echo "  optiscaler-install    - Configure OptiScaler for your games"
    echo "  optiscaler-uninstall  - Remove OptiScaler installations"
    echo "  optiscaler-update     - Update OptiScaler Universal"
    echo "  optiscaler-diagnose   - Diagnose system and games"
    echo "  optiscaler-benchmark  - Benchmark performance"
    echo ""
    echo "Documentation: /usr/share/doc/optiscaler-universal/"
    echo "Quick start:   optiscaler-install"
    echo ""
}

post_upgrade() {
    post_install
}
EOF

# Check files
ls -la
```

---

### Step 10: Commit and Push to AUR (2 minutes)

```bash
# Still in ~/aur-optiscaler-universal

# Add files
git add PKGBUILD .SRCINFO optiscaler-universal.install

# Commit with descriptive message
git commit -m "Initial import: optiscaler-universal 0.1.0-alpha

Intelligent OptiScaler configuration tool for Linux gaming.
Automatically detects GPU (AMD/Intel/NVIDIA) and applies optimal settings.

Features:
- Automatic GPU detection and driver validation
- 10 pre-configured game profiles
- Steam library integration
- Automatic backups and rollback
- Safe installation (no root required)

Supports: AMD RDNA1/2/3/4, Intel Arc, NVIDIA RTX
Games: Cyberpunk 2077, Starfield, RDR2, and more

Project: https://github.com/ind4skylivey/0ptiscaler4linux"

# Push to AUR
git push origin master
```

---

### Step 11: Verify on AUR (1 minute)

**Check your package:**

1. Go to: https://aur.archlinux.org/packages/optiscaler-universal
2. You should see:
   - Package details
   - PKGBUILD visible
   - Installation instructions
3. Test installation command shown on the page

---

### Step 12: Test with AUR Helper (Optional)

**If you have Arch:**

```bash
# Using yay
yay -S optiscaler-universal

# Or using paru
paru -S optiscaler-universal

# Test it works
optiscaler-install
```

---

## 🎉 Success!

Once published, users can install with:

```bash
yay -S optiscaler-universal
# or
paru -S optiscaler-universal
```

---

## 📢 Next Steps After Publishing

1. **Announce on social media:**
   - r/archlinux: "New package: optiscaler-universal"
   - r/linux_gaming: "OptiScaler Universal now on AUR"
   - Twitter/X: "#ArchLinux #LinuxGaming"

2. **Update your README:**
   Add installation section:
   ```markdown
   ### Arch Linux / Manjaro
   
   \`\`\`bash
   yay -S optiscaler-universal
   # or
   paru -S optiscaler-universal
   \`\`\`
   ```

3. **Monitor:**
   - Check AUR comments regularly
   - Respond to issues
   - Update when you release new versions

---

## 🔄 Updating the Package (Future Releases)

When you release v0.2.0:

```bash
# 1. Create GitHub release v0.2.0
git tag -a v0.2.0 -m "Release v0.2.0"
git push origin v0.2.0

# 2. Get new hash
wget https://github.com/ind4skylivey/0ptiscaler4linux/archive/v0.2.0.tar.gz
sha256sum v0.2.0.tar.gz

# 3. Update PKGBUILD
cd ~/aur-optiscaler-universal
nano PKGBUILD
# Change: pkgver=0.2.0, pkgrel=1, update hash

# 4. Regenerate .SRCINFO
makepkg --printsrcinfo > .SRCINFO

# 5. Commit and push
git add PKGBUILD .SRCINFO
git commit -m "Update to 0.2.0"
git push origin master
```

---

## 🆘 Troubleshooting

### SSH Permission Denied
**Problem:** Can't push to AUR
**Solution:** Check SSH key is added to AUR account

### Invalid Signature
**Problem:** Hash mismatch
**Solution:** Recalculate sha256sum and update PKGBUILD

### Package Not Building
**Problem:** makepkg fails
**Solution:** Check dependencies in PKGBUILD, test locally

### AUR Out of Date
**Problem:** Someone flagged package as outdated
**Solution:** Update to latest version or comment why it's current

---

## 📞 Getting Help

- **AUR Wiki:** https://wiki.archlinux.org/title/AUR_submission_guidelines
- **AUR Support:** aur-general@archlinux.org
- **IRC:** #archlinux-aur on Libera.Chat

---

## ✅ Final Checklist

Before submitting:

- [ ] GitHub release created with v0.1.0 tag
- [ ] SHA256 hash obtained and added to PKGBUILD
- [ ] Maintainer info updated in PKGBUILD
- [ ] .SRCINFO generated
- [ ] SSH key added to AUR account
- [ ] Files committed to AUR git repo
- [ ] Package visible on aur.archlinux.org
- [ ] Installation tested (if possible)

---

**Time estimate: 20-30 minutes total**

**Difficulty: Easy** (just follow the steps)

Good luck! 🚀
