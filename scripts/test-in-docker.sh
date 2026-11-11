#!/bin/bash
# Install a camvistra .deb into a clean Ubuntu container of the matching
# release and start the application on this machine's X display. Tests that
# apt resolves every dependency from a fresh system and that the app launches,
# e.g. the noble (24.04) package from a 22.04 machine.
#
#   sudo scripts/test-in-docker.sh noble build-output/noble-amd64/camvistra_1.0.0.19-1~noble1_amd64.deb
#
# Cameras: /dev/video*, /dev/hidraw* and USB are passed through (--privileged);
# network cameras work through --network host.
set -euo pipefail

SERIES=${1:?usage: $0 <focal|jammy|noble> <camvistra .deb>}
DEB=$(realpath "${2:?usage: $0 <focal|jammy|noble> <camvistra .deb>}")

# Allow the container (root) to open windows on the desktop's X server.
if [ -n "${SUDO_USER:-}" ]; then
    sudo -u "$SUDO_USER" DISPLAY="${DISPLAY:-:0}" xhost +si:localuser:root >/dev/null
fi

docker run --rm -it \
    --privileged -v /dev:/dev \
    --network host \
    -e DISPLAY="${DISPLAY:-:0}" -e QT_X11_NO_MITSHM=1 \
    -e QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox" \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v "$DEB:/tmp/$(basename "$DEB"):ro" \
    "ubuntu:$SERIES" bash -euc "
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y /tmp/$(basename "$DEB")
echo
dpkg -L camvistra | grep -E '^/usr/(bin|lib/lib)'
echo
echo '== Starting camvistra (close the window to finish)'
camvistra
"
