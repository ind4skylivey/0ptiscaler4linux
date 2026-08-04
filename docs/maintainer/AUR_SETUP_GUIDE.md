# AUR Setup Guide for OptiScaler Universal

Complete guide to create and maintain the AUR package.

## 📋 Prerequisites

### 1. **AUR Account**
- Create account at: https://aur.archlinux.org/register
- Setup SSH key: https://aur.archlinux.org/
- Add your public SSH key to your AUR account

### 2. **Required Tools** (on Arch/Manjaro)
```bash
sudo pacman -S base-devel git namcap
```

### 3. **AUR Helper** (optional, for testing)
```bash
# Install yay or paru
sudo pacman -S yay
# or
sudo pacman -S paru
```

---

## 🚀 Step-by-Step Setup

### Step 1: Create a GitHub Release

**IMPORTANT:** AUR packages need a stable release tarball

```bash
# 1. Tag the release
git tag -a v0.1.0 -m "Release v0.1.0-alpha"
git push origin v0.1.0

# 2. Create release on GitHub
# Go to: https://github.com/ind4skylivey/0ptiscaler4linux/releases/new
# - Tag: v0.1.0
# - Title: v0.1.0-alpha - First Alpha Release
# - Description: (copy from ANNOUNCEMENT.md)
# - Publish release

# 3. Get the tarball SHA256
wget https://github.com/ind4skylivey/0ptiscaler4linux/archive/v0.1.0.tar.gz
sha256sum v0.1.0.tar.gz
# Copy the hash for PKGBUILD
```

### Step 2: Update PKGBUILD with Real Hash

Edit `PKGBUILD`:
```bash
sha256sums=('PUT_HASH_HERE')  # Replace SKIP with actual hash
```

### Step 3: Test Build Locally

```bash
# In the project directory
cd /home/il1v3y/optiscaler-universal

# Test build
makepkg -si

# This will:
# - Download the source
# - Build the package
# - Install it locally for testing

# Test the installed commands
optiscaler-install --help
optiscaler-diagnose --verbose
```

### Step 4: Validate with namcap

```bash
# Check PKGBUILD
namcap PKGBUILD

# Check generated package
namcap optiscaler-universal-0.1.0-1-any.pkg.tar.zst

# Fix any warnings/errors reported
```

### Step 5: Generate .SRCINFO

```bash
# Generate .SRCINFO from PKGBUILD
makepkg --printsrcinfo > .SRCINFO

# Verify it looks correct
cat .SRCINFO
```

### Step 6: Clone AUR Repository

```bash
# Clone your AUR repo (creates new empty repo)
git clone ssh://aur@aur.archlinux.org/optiscaler-universal.git aur-optiscaler-universal
cd aur-optiscaler-universal

# Copy files
cp ../PKGBUILD .
cp ../.SRCINFO .

# Optionally add install message
cat > optiscaler-universal.install << 'EOF'
post_install() {
    echo ""
    echo "==> OptiScaler Universal installed!"
    echo "==> Run 'optiscaler-install' to configure your games"
    echo "==> Documentation: /usr/share/doc/optiscaler-universal/"
    echo ""
}

post_upgrade() {
    post_install
}
EOF
```

### Step 7: Commit and Push to AUR

```bash
# Add files
git add PKGBUILD .SRCINFO optiscaler-universal.install

# Commit
git commit -m "Initial import: optiscaler-universal 0.1.0-alpha

Intelligent OptiScaler configuration tool for Linux gaming.
Automatically detects GPU and applies optimal settings.

- Supports AMD (RDNA1/2/3/4), Intel Arc, NVIDIA RTX
- 10 pre-configured game profiles
- Automatic backups and safety features
- Steam integration"

# Push to AUR
git push origin master
```

### Step 8: Verify on AUR Website

Visit: https://aur.archlinux.org/packages/optiscaler-universal

You should see:
- Package information
- PKGBUILD visible
- Install command available

---

## 🔧 Testing Installation

### Test with AUR Helper

```bash
# Using yay
yay -S optiscaler-universal

# Or using paru
paru -S optiscaler-universal

# Test the commands
optiscaler-install
optiscaler-diagnose --verbose
optiscaler-update --check-only
```

### Test Manual Installation

```bash
# Clone and build
git clone https://aur.archlinux.org/optiscaler-universal.git
cd optiscaler-universal
makepkg -si
```

---

## 📦 Creating the -git Version

For development version (always latest from main):

```bash
# Clone -git repo
git clone ssh://aur@aur.archlinux.org/optiscaler-universal-git.git
cd optiscaler-universal-git

# Copy PKGBUILD-git as PKGBUILD
cp ../PKGBUILD-git PKGBUILD

# Generate .SRCINFO
makepkg --printsrcinfo > .SRCINFO

# Commit
git add PKGBUILD .SRCINFO
git commit -m "Initial import: optiscaler-universal-git

Development version of OptiScaler Universal.
Always builds from latest git main branch."

git push origin master
```

---

## 🔄 Updating the Package

When you release a new version:

### 1. Update PKGBUILD

```bash
# Edit PKGBUILD
pkgver=0.2.0  # New version
pkgrel=1      # Reset to 1 for new version

# Get new tarball hash
wget https://github.com/ind4skylivey/0ptiscaler4linux/archive/v0.2.0.tar.gz
sha256sum v0.2.0.tar.gz

# Update hash in PKGBUILD
sha256sums=('NEW_HASH_HERE')
```

### 2. Test Build

```bash
makepkg -si
namcap PKGBUILD
namcap optiscaler-universal-*.pkg.tar.zst
```

### 3. Update .SRCINFO

```bash
makepkg --printsrcinfo > .SRCINFO
```

### 4. Commit and Push

```bash
git add PKGBUILD .SRCINFO
git commit -m "Update to version 0.2.0

- List of changes
- New features
- Bug fixes"

git push origin master
```

---

## 🐛 Troubleshooting

### "Permission denied (publickey)"

**Problem:** SSH key not added to AUR account

**Solution:**
```bash
# Generate SSH key if you don't have one
ssh-keygen -t ed25519 -C "your.email@example.com"

# Copy public key
cat ~/.ssh/id_ed25519.pub

# Add to AUR account:
# https://aur.archlinux.org/account/[YourUsername]/
```

### "ERROR: One or more files did not pass the validity check!"

**Problem:** SHA256 mismatch

**Solution:**
```bash
# Recalculate hash
sha256sum v0.1.0.tar.gz

# Update PKGBUILD with correct hash
```

### "namcap warnings"

**Common warnings and fixes:**

```bash
# Warning: Referenced library not in depends
# Add missing dependency to depends=()

# Warning: Package contains reference to $srcdir
# Check for hardcoded paths, use variables

# Warning: Unused variable
# Remove or use the variable
```

### Build fails with "command not found"

**Problem:** Missing makedepends

**Solution:**
```bash
# Add to PKGBUILD
makedepends=('git' 'python-setuptools')
```

---

## 📊 Package Maintenance

### Best Practices

1. **Version Updates**
   - Update within 24-48 hours of new release
   - Test build before pushing
   - Update .SRCINFO always

2. **Respond to Comments**
   - Check AUR comments regularly
   - Respond to bug reports
   - Help users with issues

3. **Mark Out-of-Date**
   - If someone marks it out-of-date, update ASAP
   - Or explain if it's current

4. **Orphaning**
   - If you can't maintain anymore, disown the package
   - Let others adopt it

### Monitoring

```bash
# Check package page
https://aur.archlinux.org/packages/optiscaler-universal

# RSS feed for updates
https://aur.archlinux.org/rss/packages/optiscaler-universal/

# Email notifications
# Enable in AUR account settings
```

---

## 📝 Post-Installation Message

Users will see this after installing:

```bash
==> OptiScaler Universal installed!
==> Run 'optiscaler-install' to configure your games
==> Documentation: /usr/share/doc/optiscaler-universal/

Commands available:
  optiscaler-install    - Install and configure OptiScaler
  optiscaler-uninstall  - Remove OptiScaler from games
  optiscaler-update     - Update OptiScaler Universal
  optiscaler-diagnose   - Diagnose system and games
  optiscaler-benchmark  - Benchmark performance

For help: optiscaler-install --help
```

---

## 🎯 Success Checklist

Before pushing to AUR:

- [ ] GitHub release created with tag
- [ ] PKGBUILD tested locally
- [ ] namcap validation passed
- [ ] .SRCINFO generated and up-to-date
- [ ] All files committed to AUR git
- [ ] Package builds and installs correctly
- [ ] Commands work after installation
- [ ] Documentation accessible

---

## 📞 Getting Help

### AUR Resources
- **Wiki:** https://wiki.archlinux.org/title/AUR_submission_guidelines
- **Mailing List:** aur-general@archlinux.org
- **IRC:** #archlinux-aur on Libera.Chat

### Community
- Ask in AUR comments
- Post on Arch forums
- r/archlinux subreddit

---

## 🎓 Learning Resources

- [PKGBUILD Reference](https://wiki.archlinux.org/title/PKGBUILD)
- [AUR Submission Guidelines](https://wiki.archlinux.org/title/AUR_submission_guidelines)
- [namcap](https://wiki.archlinux.org/title/Namcap)
- [Example PKGBUILDs](https://aur.archlinux.org/packages/)

---

## 🚀 Ready to Publish?

Once everything is tested and working:

1. Create the GitHub release
2. Update PKGBUILD with real hash
3. Test build locally
4. Push to AUR
5. Announce on social media!

**Good luck with your first AUR package!** 🎉
