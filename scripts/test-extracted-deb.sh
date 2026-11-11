#!/bin/bash
# Test a camvistra .deb without installing it: show its metadata and contents,
# check that apt could install it on this machine, check the native libraries
# resolve, then extract it and start the application from the extracted tree.
#
#   scripts/test-extracted-deb.sh build-output/jammy-amd64/camvistra_1.0.0.19-1~jammy1_amd64.deb
#   scripts/test-extracted-deb.sh <deb> --no-run        # checks only
#
# The .deb must match this machine's Ubuntu release and architecture. The
# application's runtime dependencies (PyQt5, QML modules, ...) must be
# installed; the apt check below lists any that are missing.
set -uo pipefail

DEB=$(realpath "${1:?usage: $0 <camvistra .deb> [--no-run]}")
RUN=1
[ "${2:-}" = --no-run ] && RUN=0

DEB_ARCH=$(dpkg-deb -f "$DEB" Architecture)
HOST_ARCH=$(dpkg --print-architecture)

echo "== Package"
dpkg-deb -f "$DEB" Package Version Architecture Depends | fold -s -w 120
echo
echo "== Contents (summary)"
dpkg-deb -c "$DEB" | awk '{print $6}' | grep -v '/$' | sed -E 's#^\./##' \
    | awk -F/ '{print "/"$1"/"$2"/"$3}' | sort | uniq -c

if [ "$DEB_ARCH" != "$HOST_ARCH" ]; then
    echo
    echo "This is an $DEB_ARCH package and this machine is $HOST_ARCH: copy it to an"
    echo "$DEB_ARCH machine running the matching Ubuntu release and run this script there."
    exit 0
fi

echo
echo "== Can apt install it here? (simulation, nothing is installed)"
if apt-get install -s "$DEB" >/tmp/camvistra-apt-sim.$$ 2>&1; then
    grep -E '^Inst ' /tmp/camvistra-apt-sim.$$ | awk '{print "  would install:", $2}'
    echo "  OK: all dependencies are installable"
else
    sed 's/^/  /' /tmp/camvistra-apt-sim.$$
    echo "  Missing dependencies above; install them with: sudo apt install <package>"
fi
rm -f /tmp/camvistra-apt-sim.$$

X=$(mktemp -d /tmp/camvistra-extract.XXXXXX)
dpkg-deb -x "$DEB" "$X"
echo
echo "== Extracted to $X"

echo
echo "== Native library resolution (only 'not found' lines are problems)"
export LD_LIBRARY_PATH="$X/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fail=0
for so in "$X"/usr/lib/lib*.so "$X"/usr/lib/camvistra/camvistra/_native*.so; do
    missing=$(ldd "$so" | grep 'not found')
    if [ -n "$missing" ]; then
        echo "  $(basename "$so"):"; echo "$missing" | sed 's/^/    /'; fail=1
    fi
    if readelf -d "$so" | grep -qE 'RPATH|RUNPATH'; then
        echo "  $(basename "$so"): still has $(readelf -d "$so" | grep -E 'RPATH|RUNPATH' | awk '{print $NF}')"
    fi
done
[ $fail = 0 ] && echo "  OK: every library resolves"

echo
echo "== Python import check"
export PYTHONPATH="$X/usr/lib/camvistra"
if python3 -c 'import camvistra.native as n; print("  OK: _native loaded from", n.sdk.__file__)'; then :; else
    echo "  FAILED: see the traceback above"; fail=1
fi

if [ $RUN = 1 ]; then
    echo
    echo "== Starting CamVistra from the extracted tree (close the window to finish)"
    echo "   USB camera controls (HID) usually need root; for the full test install the"
    echo "   package and run camvistra-root-launcher instead."
    QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox" python3 -m camvistra
    echo "exit status: $?"
fi

echo
echo "Remove the extracted tree with: rm -rf $X"
exit $fail
