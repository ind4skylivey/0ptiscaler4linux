# Packaging Guide for OptiScaler Universal

This guide explains how to package OptiScaler Universal for different distribution methods.

## Current Distribution Method ✅

**Git Clone + Direct Execution** (Recommended for Alpha)

```bash
git clone https://github.com/ind4skylivey/0ptiscaler4linux.git
cd optiscaler-universal
bash scripts/install.sh
```

**Advantages:**
- Simple and straightforward
- Easy to update (`git pull` or `update.sh`)
- No packaging overhead
- Perfect for active development

---

## Future Packaging Options

### 🥇 Priority 1: AUR (Arch User Repository)

**When:** Project reaches 100+ stars
**Effort:** Low
**Impact:** High for Arch/Manjaro users

#### Steps to Create AUR Package:

1. **Create PKGBUILD**
```bash
# Maintainer: Your Name <your.email@example.com>
pkgname=optiscaler-universal
pkgver=0.1.0
pkgrel=1
pkgdesc="Intelligent OptiScaler configuration tool for Linux gaming"
arch=('any')
url="https://github.com/ind4skylivey/0ptiscaler4linux"
license=('MIT')
depends=('bash>=4.0' 'pciutils' 'mesa-utils')
optdepends=(
    'python: for advanced YAML parsing'
    'git-lfs: for downloading binaries'
)
source=("$pkgname-$pkgver.tar.gz::$url/archive/v$pkgver.tar.gz")
sha256sums=('SKIP')

package() {
    cd "$srcdir/$pkgname-$pkgver"
    
    # Install scripts
    install -dm755 "$pkgdir/usr/share/$pkgname"
    cp -r core lib profiles scripts templates "$pkgdir/usr/share/$pkgname/"
    
    # Install executables
    install -dm755 "$pkgdir/usr/bin"
    ln -s "/usr/share/$pkgname/scripts/install.sh" "$pkgdir/usr/bin/optiscaler-install"
    ln -s "/usr/share/$pkgname/scripts/uninstall.sh" "$pkgdir/usr/bin/optiscaler-uninstall"
    ln -s "/usr/share/$pkgname/scripts/update.sh" "$pkgdir/usr/bin/optiscaler-update"
    ln -s "/usr/share/$pkgname/scripts/diagnose.sh" "$pkgdir/usr/bin/optiscaler-diagnose"
    
    # Install documentation
    install -dm755 "$pkgdir/usr/share/doc/$pkgname"
    cp -r docs/* "$pkgdir/usr/share/doc/$pkgname/"
    install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
    
    # Install license
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
```

2. **Test locally**
```bash
makepkg -si
```

3. **Submit to AUR**
```bash
git clone ssh://aur@aur.archlinux.org/optiscaler-universal.git
cd optiscaler-universal
# Add PKGBUILD, .SRCINFO
git add .
git commit -m "Initial import: optiscaler-universal 0.1.0"
git push
```

#### AUR -git Version

For development version:
```bash
pkgname=optiscaler-universal-git
pkgver=r100.45765a0  # Updated by pkgver()
source=("git+https://github.com/ind4skylivey/0ptiscaler4linux.git")

pkgver() {
    cd "$srcdir/$pkgname"
    printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}
```

---

### 🥈 Priority 2: Flatpak

**When:** Project reaches 500+ stars
**Effort:** Medium
**Impact:** Universal Linux distribution

#### Create Flatpak Manifest

**File:** `com.github.ind4skylivey.OptiScalerUniversal.yml`

```yaml
app-id: com.github.ind4skylivey.OptiScalerUniversal
runtime: org.freedesktop.Platform
runtime-version: '23.08'
sdk: org.freedesktop.Sdk
command: optiscaler-universal

finish-args:
  - --share=ipc
  - --socket=x11
  - --device=dri
  - --filesystem=home
  - --filesystem=~/.local/share/Steam:rw

modules:
  - name: optiscaler-universal
    buildsystem: simple
    build-commands:
      - install -dm755 /app/share/optiscaler-universal
      - cp -r core lib profiles scripts templates /app/share/optiscaler-universal/
      - install -Dm755 scripts/install.sh /app/bin/optiscaler-universal
      - install -Dm644 README.md /app/share/doc/optiscaler-universal/README.md
    sources:
      - type: archive
        url: https://github.com/ind4skylivey/0ptiscaler4linux/archive/v0.1.0.tar.gz
        sha256: HASH_HERE
```

#### Build and Test
```bash
flatpak-builder --user --install build-dir com.github.ind4skylivey.OptiScalerUniversal.yml
flatpak run com.github.ind4skylivey.OptiScalerUniversal
```

#### Publish to Flathub
1. Fork https://github.com/flathub/flathub
2. Add your manifest
3. Submit PR

---

### 🥉 Priority 3: AppImage

**When:** Community requests it
**Effort:** Medium
**Impact:** Portable single-file distribution

#### Create AppImage

**File:** `AppImageBuilder.yml`

```yaml
version: 1
AppDir:
  path: ./AppDir
  app_info:
    id: com.github.ind4skylivey.optiscaler-universal
    name: OptiScaler Universal
    icon: optiscaler-universal
    version: 0.1.0
    exec: usr/bin/optiscaler-install
    
  files:
    include:
      - usr/share/optiscaler-universal
      - usr/bin/optiscaler-*
      - usr/share/doc/optiscaler-universal
      
  runtime:
    env:
      APPDIR_LIBRARY_PATH: $APPDIR/usr/lib

AppImage:
  arch: x86_64
  update-information: gh-releases-zsync|ind4skylivey|0ptiscaler4linux|latest|*x86_64.AppImage.zsync
```

#### Build
```bash
appimage-builder --recipe AppImageBuilder.yml
```

---

### 📦 Priority 4: DEB/RPM Packages

**When:** Stable 1.0 release with high demand
**Effort:** High
**Impact:** Official distro repositories

#### Debian/Ubuntu Package

**Directory structure:**
```
optiscaler-universal-0.1.0/
├── debian/
│   ├── control
│   ├── rules
│   ├── changelog
│   ├── copyright
│   └── install
└── (source files)
```

**debian/control:**
```
Source: optiscaler-universal
Section: games
Priority: optional
Maintainer: Your Name <email@example.com>
Build-Depends: debhelper (>= 10)
Standards-Version: 4.5.0
Homepage: https://github.com/ind4skylivey/0ptiscaler4linux

Package: optiscaler-universal
Architecture: all
Depends: bash (>= 4.0), pciutils, ${misc:Depends}
Recommends: mesa-utils, git-lfs
Description: Intelligent OptiScaler configurator for Linux gaming
 OptiScaler Universal automatically detects your GPU and configures
 OptiScaler optimally for your specific hardware and games, bringing
 FSR4, XeSS, and enhanced DLSS quality to Linux gaming.
```

**Build:**
```bash
dpkg-buildpackage -us -uc
```

#### RPM Package (Fedora/openSUSE)

**optiscaler-universal.spec:**
```spec
Name:           optiscaler-universal
Version:        0.1.0
Release:        1%{?dist}
Summary:        Intelligent OptiScaler configurator for Linux gaming

License:        MIT
URL:            https://github.com/ind4skylivey/0ptiscaler4linux
Source0:        %{url}/archive/v%{version}.tar.gz

BuildArch:      noarch
Requires:       bash >= 4.0
Requires:       pciutils
Recommends:     mesa-demos
Recommends:     git-lfs

%description
OptiScaler Universal automatically detects your GPU and configures
OptiScaler optimally for your specific hardware and games.

%prep
%autosetup

%install
install -dm755 %{buildroot}%{_datadir}/%{name}
cp -r core lib profiles scripts templates %{buildroot}%{_datadir}/%{name}/

install -dm755 %{buildroot}%{_bindir}
ln -s %{_datadir}/%{name}/scripts/install.sh %{buildroot}%{_bindir}/optiscaler-install
ln -s %{_datadir}/%{name}/scripts/uninstall.sh %{buildroot}%{_bindir}/optiscaler-uninstall

%files
%license LICENSE
%doc README.md docs/*
%{_datadir}/%{name}/
%{_bindir}/optiscaler-*

%changelog
* Sun Oct 26 2025 Your Name <email@example.com> - 0.1.0-1
- Initial package
```

**Build:**
```bash
rpmbuild -ba optiscaler-universal.spec
```

---

## 🎯 Recommended Roadmap

### Alpha (Current) - v0.1.0
- ✅ Git clone method
- ✅ Direct script execution
- ✅ Update via `update.sh`

### Beta - v0.2.0
- 📦 AUR package (optiscaler-universal-git)
- 📦 AUR stable (optiscaler-universal)
- 📝 Installation instructions updated

### Stable - v1.0.0
- 🎁 Flatpak on Flathub
- 📦 AppImage releases on GitHub
- 📚 Comprehensive packaging docs

### Post-1.0
- 📦 Debian PPA
- 📦 Fedora COPR
- 📦 Official distro repos (long-term goal)

---

## 🛠️ Tools & Resources

### Packaging Tools
- **Arch**: `makepkg`, `namcap` (PKGBUILD linter)
- **Flatpak**: `flatpak-builder`, `flatpak-spawn`
- **AppImage**: `appimage-builder`, `appimagetool`
- **DEB**: `dpkg-buildpackage`, `debhelper`, `lintian`
- **RPM**: `rpmbuild`, `rpmlint`

### Testing
```bash
# Test in containers
docker run -it archlinux bash
docker run -it ubuntu:24.04 bash
docker run -it fedora:40 bash

# Test locally
vagrant init archlinux/archlinux
vagrant up
vagrant ssh
```

### Validation
```bash
# Arch
namcap PKGBUILD
namcap optiscaler-universal-0.1.0-1-any.pkg.tar.zst

# Debian
lintian optiscaler-universal_0.1.0-1_all.deb

# RPM
rpmlint optiscaler-universal.spec
rpmlint optiscaler-universal-0.1.0-1.noarch.rpm
```

---

## 📞 Community Feedback

Before investing time in packaging:

1. **Survey users** via GitHub Discussions
2. **Check interest** on r/linux_gaming
3. **Monitor requests** in GitHub Issues
4. **Gauge downloads** and stars

Let demand drive packaging decisions!

---

## 🔗 Useful Links

- [Arch Packaging Standards](https://wiki.archlinux.org/title/PKGBUILD)
- [Flatpak Documentation](https://docs.flatpak.org/)
- [AppImage Best Practices](https://docs.appimage.org/)
- [Debian Packaging Guide](https://www.debian.org/doc/manuals/maint-guide/)
- [Fedora Packaging Guidelines](https://docs.fedoraproject.org/en-US/packaging-guidelines/)

---

**Current Status:** ✅ Git clone method is perfect for Alpha release  
**Next Step:** Wait for community feedback before packaging
