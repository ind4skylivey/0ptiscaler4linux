#!/usr/bin/env bash
set -euo pipefail

# Paths
MAIN_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUR_STABLE_SRC="$MAIN_REPO/aur-optiscaler-universal"
AUR_GIT_SRC="$MAIN_REPO/aur-optiscaler-universal-git"

# Default targets
AUR_STABLE_DEST="${AUR_STABLE_DEST:-$HOME/aur/optiscaler-universal}"
AUR_GIT_DEST="${AUR_GIT_DEST:-$HOME/aur/optiscaler-universal-git}"

usage() {
    cat << EOF
Usage: $(basename "$0") [stable|git|both]

Sync PKGBUILD files from the in-repo AUR sources to local AUR clone directories.

Targets:
  stable  Sync aur-optiscaler-universal/ -> $AUR_STABLE_DEST
  git     Sync aur-optiscaler-universal-git/ -> $AUR_GIT_DEST
  both    Sync both (default)

Environment:
  AUR_STABLE_DEST  Override stable AUR clone path (default: ~/aur/optiscaler-universal)
  AUR_GIT_DEST     Override git AUR clone path (default: ~/aur/optiscaler-universal-git)
EOF
}

sync_pkg() {
    local src_dir="$1"
    local dest_dir="$2"
    local label="$3"

    if [[ ! -d "$dest_dir" || ! -d "$dest_dir/.git" ]]; then
        echo "[$label] AUR repository not found at $dest_dir"
        echo ""
        echo "Clone it first:"
        echo "    git clone ssh://aur@aur.archlinux.org/$(basename "$dest_dir").git $dest_dir"
        return 1
    fi

    echo "[$label] Copying PKGBUILD and .SRCINFO from $src_dir to $dest_dir"
    cp "$src_dir/PKGBUILD" "$dest_dir/"
    cp "$src_dir/.SRCINFO" "$dest_dir/"

    # Copy .install file if present
    for install_file in "$src_dir/"*.install; do
        [[ -f "$install_file" ]] && cp "$install_file" "$dest_dir/"
    done

    # Regenerate .SRCINFO to ensure consistency
    echo "[$label] Regenerating .SRCINFO"
    (cd "$dest_dir" && makepkg --printsrcinfo > .SRCINFO)

    echo "[$label] Diff:"
    (cd "$dest_dir" && git diff PKGBUILD .SRCINFO || true)

    echo ""
    echo "[$label] Ready to commit and push:"
    echo "    cd $dest_dir && git add -A && git commit -m '...' && git push"
}

target="${1:-both}"

case "$target" in
    stable)
        sync_pkg "$AUR_STABLE_SRC" "$AUR_STABLE_DEST" "stable"
        ;;
    git)
        sync_pkg "$AUR_GIT_SRC" "$AUR_GIT_DEST" "git"
        ;;
    both)
        sync_pkg "$AUR_STABLE_SRC" "$AUR_STABLE_DEST" "stable"
        echo ""
        sync_pkg "$AUR_GIT_SRC" "$AUR_GIT_DEST" "git"
        ;;
    -h|--help)
        usage
        ;;
    *)
        echo "Unknown target: $target" >&2
        usage >&2
        exit 1
        ;;
esac
