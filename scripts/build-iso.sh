#!/bin/sh
# BC-250-X ISO build (Buildroot external tree). Requires: git, make, gcc, docker optional.
# This script is the real pipeline entry for Phase 1; on a fresh checkout it fetches
# Buildroot, applies the BC-250-X defconfig, and produces output/bc250x-*.iso.
set -eu
cd "$(dirname "$0")/.."
BR_VER="${BUILDROOT_VERSION:-2025.02}"
mkdir -p build output
if [ ! -d build/buildroot ]; then
  curl -fsSL "https://buildroot.org/downloads/buildroot-${BR_VER}.tar.xz" | tar -xJ -C build
  mv "build/buildroot-${BR_VER}" build/buildroot
fi
make -C build/buildroot BR2_EXTERNAL="$PWD/buildroot-external" bc250x_defconfig
make -C build/buildroot BR2_EXTERNAL="$PWD/buildroot-external" -j"$(nproc)"
cp build/buildroot/output/images/*.iso output/ 2>/dev/null || cp build/buildroot/output/images/*.img output/
echo "Built: $(ls -lh output/)"
echo "NOTE: Phase 1 work — defconfig is a skeleton (see buildroot-external/configs/bc250x_defconfig)."
echo "Boot-test in QEMU:  qemu-system-x86_64 -bios OVMF.fd -cdrom output/*.iso -m 4096"
