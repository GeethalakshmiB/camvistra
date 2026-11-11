#!/bin/bash
# Build the camvistra binary .deb for one Ubuntu release and architecture in a
# clean Ubuntu container (Docker). Nothing is compiled: arm64 is cross-built on
# an amd64 machine; the arm64 libraries are only needed by dh_shlibdeps.
#
#   sudo scripts/build-local-deb.sh jammy amd64     # Ubuntu 22.04 x86_64
#   sudo scripts/build-local-deb.sh jammy arm64     # Ubuntu 22.04 aarch64 (Jetson)
#   sudo scripts/build-local-deb.sh noble amd64     # Ubuntu 24.04 x86_64
#
# Source/ is taken from master/Source, debian/ from <series>/debian (worktree of
# the release branch).
# Output: build-output/<series>-<arch>/camvistra_<version>_<arch>.deb
set -euo pipefail

usage="usage: $0 <focal|jammy|noble> <amd64|arm64>"
SERIES=${1:?$usage}
ARCH=${2:?$usage}
# This script is in <workspace>/master/scripts; release branches are worktrees
# in <workspace>/<release> (see build-source-package.sh).
ROOT=$(cd "$(dirname "$0")/../.." && pwd)

case $SERIES in
    focal) UBUNTU=20.04 ;;
    jammy) UBUNTU=22.04 ;;
    noble) UBUNTU=24.04 ;;
    *) echo "$usage"; exit 1 ;;
esac
case $ARCH in amd64|arm64) ;; *) echo "$usage"; exit 1 ;; esac

SOURCE_DIR=$ROOT/master/Source
DEBIAN_DIR=$ROOT/$SERIES/debian

LIBDIR=$SOURCE_DIR/lib/Ubuntu_$UBUNTU/$ARCH
if ! ls "$LIBDIR"/lib*.so >/dev/null 2>&1; then
    echo "error: no prebuilt SDK libraries in $LIBDIR; cannot build $SERIES/$ARCH yet" >&2
    exit 1
fi

VERSION=$(dpkg-parsechangelog -l "$DEBIAN_DIR/changelog" -S Version)
UPSTREAM=${VERSION%-*}
OUT=$ROOT/build-output/$SERIES-$ARCH
TREE=$OUT/camvistra-$UPSTREAM

rm -rf "$OUT"
mkdir -p "$TREE"
cp -a "$SOURCE_DIR" "$TREE/Source"
find "$TREE/Source" -name __pycache__ -type d -prune -exec rm -rf {} +
rm -rf "$TREE/Source/build"
cp -a "$DEBIAN_DIR" "$TREE/debian"

echo "Building camvistra $VERSION for $SERIES/$ARCH from $SOURCE_DIR"

docker run --rm \
    -e SERIES="$SERIES" -e ARCH="$ARCH" \
    -v "$OUT:/build" -w "/build/camvistra-$UPSTREAM" \
    "ubuntu:$SERIES" bash -euxc '
export DEBIAN_FRONTEND=noninteractive

if [ "$ARCH" = arm64 ]; then
    # The default mirrors only carry amd64; arm64 comes from ports.ubuntu.com.
    if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then      # noble+ (deb822)
        sed -i "/^Types:/a Architectures: amd64" /etc/apt/sources.list.d/ubuntu.sources
        printf "Types: deb\nURIs: http://ports.ubuntu.com/ubuntu-ports\nSuites: %s %s-updates %s-security\nComponents: main universe\nArchitectures: arm64\n" \
            "$SERIES" "$SERIES" "$SERIES" > /etc/apt/sources.list.d/ports.sources
    else                                                        # focal, jammy
        sed -i "s/^deb /deb [arch=amd64] /" /etc/apt/sources.list
        for s in "$SERIES" "$SERIES-updates" "$SERIES-security"; do
            echo "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports $s main universe" >> /etc/apt/sources.list
        done
    fi
    dpkg --add-architecture arm64
fi

apt-get update
apt-get install -y --no-install-recommends build-essential dpkg-dev

if [ "$ARCH" = amd64 ]; then
    # Install exactly the Build-Depends from debian/control, as Launchpad does.
    apt-get build-dep -y ./
    dpkg-buildpackage -b -us -uc
else
    # Native tools + the arm64 libraries dh_shlibdeps looks up.
    apt-get install -y --no-install-recommends \
        debhelper dh-python python3 patchelf binutils-aarch64-linux-gnu
    apt-get install -y --no-install-recommends \
        libavcodec-dev:arm64 libavformat-dev:arm64 libavutil-dev:arm64 \
        libswscale-dev:arm64 libcurl4-openssl-dev:arm64 libpulse-dev:arm64 \
        libturbojpeg0-dev:arm64 libudev-dev:arm64 libxml2-dev:arm64 \
        libglib2.0-dev:arm64 libgstreamer1.0-dev:arm64 \
        libgstreamer-plugins-base1.0-dev:arm64
    dpkg-buildpackage -aarm64 -d -b -us -uc
fi
'

# Files written by the container are root-owned; give them back to the caller.
if [ -n "${SUDO_UID:-}" ]; then
    chown -R "$SUDO_UID:$SUDO_GID" "$ROOT/build-output"
fi

echo
echo "Built:"
ls -1 "$OUT"/*.deb
for deb in "$OUT"/camvistra_*.deb; do
    echo
    echo "== $(basename "$deb")"
    dpkg-deb -f "$deb" Package Version Architecture Depends
done
