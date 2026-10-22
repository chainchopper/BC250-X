#!/bin/sh
# One-session Phase 1 pipeline: install tools -> build ISO -> QEMU test.
# Exists because this VM's root overlay does not persist across sessions;
# everything must happen in one run. Outputs land in the project (persistent):
#   output/bc250x-phase1-<date>.iso , build/phase1-full.log , build/qemu-drive.log
set -x
cd "$(dirname "$0")/.."
mkdir -p build output
sed -i 's# http://mirror.cogentco.com/pub/linux/ubuntu##' /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null || true
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  qemu-system-x86 ovmf xorriso busybox-static cpio mtools dosfstools \
  grub-efi-amd64-bin grub-common linux-image-6.8.0-147-generic linux-modules-6.8.0-147-generic \
  kmod python3 || exit 11
for t in qemu-system-x86_64 xorriso grub-mkstandalone busybox cpio mformat mkfs.vfat; do command -v $t || exit 12; done
ls /boot/vmlinuz-* /usr/share/OVMF/OVMF_CODE_4M.fd || exit 13
./scripts/build-iso-phase1.sh || exit 14
python3 scripts/test-qemu-drive.py; TEST=$?
cp /tmp/bc250x-qemu-drive.log build/qemu-drive.log 2>/dev/null || true
echo "QEMU_TEST_EXIT=$TEST"
ls -lh output/
exit $TEST
