#!/bin/sh
# BC-250-X rootfs post-build step (runs after target install, before the
# cpio image is generated; $1 = target dir).
#
# Injects the genuine BIOS payload ROMs from build/payload/ into
# /usr/share/bc250x/payload/. The ROMs are build-time downloads (community
# images from gitlab.com/TuxThePenguin0/bc250-bios) and deliberately live
# OUTSIDE the git tree — 32 MB of third-party binaries don't belong in the
# repo. If build/payload/ is empty the image is built without ROMs and
# this script says so loudly; `bc250x verify/pray` then have nothing to
# verify until a payload is staged.
set -eu
TARGET="$1"
# This script lives at buildroot-external/board/bc250x/post-build.sh —
# three levels up is the project root.
PROJ="$(cd "$(dirname "$0")/../../.." && pwd)"
SRC="$PROJ/build/payload"
DST="$TARGET/usr/share/bc250x/payload"

if [ -d "$SRC" ] && ls "$SRC"/*.ROM >/dev/null 2>&1; then
  mkdir -p "$DST"
  for rom in "$SRC"/*.ROM; do
    sz=$(stat -c%s "$rom")
    if [ "$sz" = "16777216" ]; then
      cp "$rom" "$DST/"
      echo "bc250x post-build: payload $(basename "$rom") ($sz bytes) -> /usr/share/bc250x/payload/"
    else
      echo "bc250x post-build: WARNING skipping $(basename "$rom"): size $sz != 16777216 (not a BC-250 BIOS image)" >&2
    fi
  done
else
  echo "bc250x post-build: NOTE: no payload ROMs in build/payload/ — image ships without BIOS payloads"
fi
