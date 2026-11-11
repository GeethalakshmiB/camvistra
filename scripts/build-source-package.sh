#!/bin/bash
# Build the signed source package of one Ubuntu release for upload to its
# Launchpad PPA (ppa:<launchpad-user>/camvistra-<release>). Launchpad builds
# the binary packages (amd64, arm64) from it.
#
#   scripts/build-source-package.sh jammy <GPG key fingerprint>
#   scripts/build-source-package.sh jammy --unsigned     # local check, not uploadable
#   dput camvistra-jammy build-output/source/jammy/camvistra_<version>_source.changes
#
# Expected layout (a clone of the repository plus worktrees of the release
# branches; GitHub Actions checks out the same layout):
#
#   <workspace>/master/            branch master: Source/, scripts/
#   <workspace>/<release>/debian/  branch <release>: debian/ only
#   <workspace>/build-output/      written by this script
#
# The upstream tarball camvistra_<upstream>.orig.tar.xz is made from Source/
# and reused for every release of the same upstream version. Changing Source/
# needs a new upstream version in debian/changelog (1.0.0.20-1~jammy1, ...).
#
# Needs: dpkg-dev, devscripts (debsign), xz-utils and, unless --unsigned, the
# GPG key registered on the Launchpad account that owns the PPA.
set -euo pipefail

usage="usage: $0 <focal|jammy|noble> <GPG key fingerprint | --unsigned>"
SERIES=${1:?$usage}
KEY=${2:?$usage}
WORKSPACE=$(cd "$(dirname "$0")/../.." && pwd)

case $SERIES in
    focal) UBUNTU=20.04 ;;
    jammy) UBUNTU=22.04 ;;
    noble) UBUNTU=24.04 ;;
    *) echo "$usage" >&2; exit 1 ;;
esac

SOURCE_DIR=$WORKSPACE/master/Source
DEBIAN_DIR=$WORKSPACE/$SERIES/debian
[ -d "$SOURCE_DIR" ] || { echo "error: $SOURCE_DIR not found" >&2; exit 1; }
[ -f "$DEBIAN_DIR/changelog" ] || {
    echo "error: $DEBIAN_DIR not found; add the branch with: git -C $WORKSPACE/master worktree add ../$SERIES $SERIES" >&2
    exit 1
}

VERSION=$(dpkg-parsechangelog -l "$DEBIAN_DIR/changelog" -S Version)
DIST=$(dpkg-parsechangelog -l "$DEBIAN_DIR/changelog" -S Distribution)
UPSTREAM=${VERSION%-*}
[ "$DIST" = "$SERIES" ] || { echo "error: debian/changelog targets $DIST, not $SERIES" >&2; exit 1; }

# Launchpad would accept the upload and then fail every build if the prebuilt
# files for an architecture in debian/control are missing: stop here instead.
ARCHES=$(awk '/^Package:/{p=1} p && /^Architecture:/{sub(/^Architecture:[ \t]*/, ""); print; exit}' "$DEBIAN_DIR/control")
for arch in $ARCHES; do
    libdir=$SOURCE_DIR/lib/Ubuntu_$UBUNTU/$arch
    if ! ls "$libdir"/lib*.so >/dev/null 2>&1 || ! ls "$libdir"/_native.cpython-*.so >/dev/null 2>&1; then
        echo "error: debian/control builds $arch but $libdir has no SDK libraries or _native extension" >&2
        echo "       add them on master, or remove $arch from Architecture in $SERIES/debian/control" >&2
        exit 1
    fi
done

OUT=$WORKSPACE/build-output/source
ORIG=$OUT/camvistra_$UPSTREAM.orig.tar.xz
TREE=$OUT/$SERIES/camvistra-$UPSTREAM
mkdir -p "$OUT"
rm -rf "$OUT/$SERIES"
mkdir -p "$TREE"

cp -a "$SOURCE_DIR" "$TREE/Source"
find "$TREE/Source" -name __pycache__ -type d -prune -exec rm -rf {} +
rm -rf "$TREE/Source/build"

if [ ! -f "$ORIG" ]; then
    echo "Creating $ORIG"
    tar -C "$OUT/$SERIES" --sort=name --mtime='2026-01-01 00:00Z' \
        --owner=0 --group=0 --numeric-owner \
        -cf - "camvistra-$UPSTREAM" | xz -9 -T1 > "$ORIG"
else
    echo "Reusing $ORIG (dpkg-source stops if Source/ no longer matches it)"
fi
ln -sf "../$(basename "$ORIG")" "$OUT/$SERIES/"

cp -a "$DEBIAN_DIR" "$TREE/debian"

# -S source only, -sa include the orig tarball, -d/-nc: no build tools needed
# here (Launchpad installs the Build-Depends).
if [ "$KEY" = --unsigned ]; then SIGN=(-us -uc); else SIGN=(-k"$KEY"); fi
(cd "$TREE" && dpkg-buildpackage -S -sa -d -nc "${SIGN[@]}")

CHANGES=$OUT/$SERIES/camvistra_${VERSION}_source.changes
echo
echo "Source package ready ($SERIES, $ARCHES):"
ls -1 "$OUT/$SERIES"/camvistra_*
echo
echo "Upload with:"
echo "  dput camvistra-$SERIES $CHANGES"
