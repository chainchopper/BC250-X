#!/bin/sh
# BC-250-X production ISO build (Buildroot + custom 6.12 LTS kernel).
#
# Pipeline:
#   1. Fetch Buildroot (pinned) into build/buildroot
#   2. bc250x_defconfig (BR2_EXTERNAL=buildroot-external): Bootlin external
#      toolchain, kernel 6.12.0 = x86_64 defconfig + kernel/bc250x-kernel.fragment,
#      busybox initramfs rootfs (rootfs.cpio.gz) with the BC-250-X overlay
#   3. make (kernel + rootfs -> build/buildroot/output/images/)
#   4. Package the ISO with the Phase 1-proven GRUB-standalone pattern:
#      FAT ESP (BOOTX64.EFI + /boot/vmlinuz + /boot/initramfs.gz) embedded
#      in a hybrid El Torito ISO. Buildroot's own iso9660 target is
#      BIOS-oriented and is not used.
#
# Output: output/bc250x-prod-<date>.iso (+ .sha256)
# Boot-test: python3 scripts/test-qemu-drive-prod.py
set -eu
cd "$(dirname "$0")/.."
ROOT="$PWD"; WORK="$ROOT/build/prod"; OUT="$ROOT/output"
BR_VER="${BUILDROOT_VERSION:-2025.02}"
JOBS="${JOBS:-2}"
mkdir -p build "$WORK" "$OUT"

# --- 1+2+3. Buildroot -------------------------------------------------------
if [ ! -d build/buildroot ]; then
  curl -fsSL "https://buildroot.org/downloads/buildroot-${BR_VER}.tar.xz" -o build/buildroot.tar.xz
  tar --no-same-owner -xJf build/buildroot.tar.xz -C build
  mv "build/buildroot-${BR_VER}" build/buildroot
  rm -f build/buildroot.tar.xz
fi
make -C build/buildroot BR2_EXTERNAL="$ROOT/buildroot-external" bc250x_defconfig
make -C build/buildroot BR2_EXTERNAL="$ROOT/buildroot-external" -j"$JOBS"

IMG="$ROOT/build/buildroot/output/images"
KERNEL="$IMG/bzImage"
INITRD="$IMG/rootfs.cpio.gz"
[ -f "$KERNEL" ] || { echo "kernel image missing: $KERNEL" >&2; exit 1; }
[ -f "$INITRD" ] || { echo "initramfs missing: $INITRD" >&2; exit 1; }
KVER="$(make -s -C build/buildroot BR2_EXTERNAL="$ROOT/buildroot-external" printvars VARS=BR2_LINUX_KERNEL_VERSION 2>/dev/null | sed -n 's/^BR2_LINUX_KERNEL_VERSION=//p' | tail -1)"
echo ">> kernel: $KERNEL (${KVER:-unknown})"
echo ">> initramfs: $(du -h "$INITRD" | cut -f1)"

# --- 4. Package ISO (Phase 1 pattern) ---------------------------------------
STAGE="$WORK/stage"; rm -rf "$STAGE"; mkdir -p "$STAGE/EFI/BOOT" "$STAGE/boot"
cp "$KERNEL" "$STAGE/boot/vmlinuz"; cp "$INITRD" "$STAGE/boot/initramfs.gz"
cat > "$WORK/grub.cfg" <<'CFG'
insmod part_gpt
insmod part_msdos
insmod fat
insmod iso9660
insmod search
insmod search_fs_file
# Standalone GRUB boots with root=memdisk (config only). Find the real root:
# the first device that actually contains our kernel (ESP or ISO9660, both ship it).
search --no-floppy --set=root --file /boot/vmlinuz
set timeout=5
set default=0
menuentry "BC-250-X - Production Live (BC-250)" {
  linux /boot/vmlinuz console=tty0 console=ttyS0,115200 bc250x.live quiet loglevel=3
  initrd /boot/initramfs.gz
}
menuentry "BC-250-X - Production Live, verbose" {
  linux /boot/vmlinuz console=tty0 console=ttyS0,115200 bc250x.live loglevel=7
  initrd /boot/initramfs.gz
}
CFG
grub-mkstandalone -O x86_64-efi -o "$STAGE/EFI/BOOT/BOOTX64.EFI" "boot/grub/grub.cfg=$WORK/grub.cfg" --modules="part_gpt part_msdos iso9660 fat ext2 normal linux all_video search search_fs_file" 2>/dev/null \
 || grub-mkstandalone -O x86_64-efi -o "$STAGE/EFI/BOOT/BOOTX64.EFI" "boot/grub/grub.cfg=$WORK/grub.cfg"
ESP="$WORK/esp.img"
ESP_KB=$(( ( $(stat -c%s "$STAGE/EFI/BOOT/BOOTX64.EFI") + $(stat -c%s "$KERNEL") + $(stat -c%s "$INITRD") ) / 1024 + 8192 ))
dd if=/dev/zero of="$ESP" bs=1K count="$ESP_KB" status=none
mkfs.vfat -F 32 -n BC250XESP "$ESP" >/dev/null
mmd -i "$ESP" ::/EFI ::/EFI/BOOT ::/boot
mcopy -i "$ESP" "$STAGE/EFI/BOOT/BOOTX64.EFI" ::/EFI/BOOT/
mcopy -i "$ESP" "$STAGE/boot/vmlinuz" "$STAGE/boot/initramfs.gz" ::/boot/
echo ">> ESP: ${ESP_KB} KB"

cp "$ESP" "$STAGE/efi.img"
ISO="$OUT/bc250x-prod-$(date +%Y%m%d).iso"
xorriso -as mkisofs -iso-level 3 -V BC250X -o "$ISO" \
  -eltorito-alt-boot -e efi.img -no-emul-boot -isohybrid-gpt-basdat "$STAGE" 2>&1 | tail -2
sha256sum "$ISO" > "$ISO.sha256"
ls -lh "$ISO"
echo ">> DONE: $ISO"
echo ">> SHA-256: $(cat "$ISO.sha256")"
echo ">> QEMU test: python3 scripts/test-qemu-drive-prod.py"
