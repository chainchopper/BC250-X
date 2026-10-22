#!/bin/sh
# BC-250-X Phase 1 ISO assembler (fast path).
#
# Why this exists alongside the Buildroot tree: Buildroot compiles a kernel +
# full system from source (hours on small CI). Phase 1's gate is narrower and
# honest: prove the boot chain end-to-end — UEFI -> kernel -> BC-250-X init ->
# bc250x status/menu — and verify it in QEMU. So this script assembles the ISO
# from the distro kernel binary (Ubuntu 24.04 linux-image, 6.8 series — the
# exact OS/kernel family owner builds have run on real BC-250s) plus a
# hand-rolled busybox initramfs carrying the bc250x CLI and Phase 1 init.
# The Buildroot/custom-kernel build remains the production path (build-iso.sh).
#
# Output: output/bc250x-phase1-<date>.iso  (UEFI El Torito, also dd-able)
set -eu
cd "$(dirname "$0")/.."
ROOT="$PWD"; WORK="$ROOT/build/phase1"; OUT="$ROOT/output"
mkdir -p "$WORK/rootfs" "$OUT"

KVER="$(ls /lib/modules | sort -V | tail -1)"
KERNEL="/boot/vmlinuz-$KVER"
[ -f "$KERNEL" ] || { echo "kernel not found: $KERNEL (install linux-image-generic)" >&2; exit 1; }
echo ">> kernel: $KERNEL (modules $KVER)"

# --- initramfs rootfs -------------------------------------------------------
R="$WORK/rootfs"
rm -rf "$R"; mkdir -p "$R/bin" "$R/sbin" "$R/proc" "$R/sys" "$R/dev" "$R/tmp" "$R/run" "$R/usr/bin" "$R/usr/share/bc250x" "$R/lib/modules"
cp "$(command -v busybox)" "$R/bin/busybox"; chmod +x "$R/bin/busybox"
cp "$ROOT/phase1/init" "$R/init"; chmod +x "$R/init"
cp "$ROOT/buildroot-external/board/bc250x/rootfs-overlay/usr/bin/bc250x" "$R/usr/bin/bc250x"; chmod +x "$R/usr/bin/bc250x"
for c in bios os tools; do cp "$ROOT/catalog/$c.json" "$R/usr/share/bc250x/$c.json"; done
# tools the init/CLI expect, from the host (static-ish set, all in busybox too)
for t in curl; do [ -x "/usr/bin/$t" ] && cp "/usr/bin/$t" "$R/usr/bin/" 2>/dev/null || true; done

# kernel modules: resolve dependency closure for the Phase 1 list
MODS="isofs cdrom sr_mod loop squashfs fat vfat nls_cp437 nls_iso8859_1 virtio virtio_pci virtio_blk virtio_net net_failover failover ahci libahci sd_mod ata_piix usb_common usbcore xhci_hcd ehci_hcd usb_storage nvme nvme_core e1000 e1000e r8169"
python3 - "$KVER" "$R" $MODS <<'PY'
import subprocess, sys, os, shutil
kver, root, mods = sys.argv[1], sys.argv[2], sys.argv[3:]
seen = set()
def add(mod):
    if mod in seen: return
    seen.add(mod)
    out = subprocess.run(['modprobe','-d','/','--show-depends','-S',kver,mod], capture_output=True, text=True).stdout
    for line in out.splitlines():
        parts = line.split()
        if len(parts) >= 2 and parts[0].startswith('insmod'):
            src = parts[1]
            dst = os.path.join(root, src.lstrip('/'))
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            if os.path.exists(src): shutil.copy2(src, dst)
        elif parts and parts[0] == 'builtin':
            pass
    # recurse into depends via modules.dep parsing is handled by show-depends ordering
for m in mods: add(m)
print(f">> modules copied: {sum(len(f) for _,_,f in os.walk(os.path.join(root,'lib','modules')))} files")
PY
depmod -b "$R" "$KVER" 2>/dev/null || true
# modprobe + depmod binaries for the initramfs
cp /sbin/modprobe "$R/sbin/modprobe" 2>/dev/null || cp "$(command -v modprobe)" "$R/sbin/"
# shared libs for modprobe/curl (busybox covers the rest)
for b in "$R/sbin/modprobe" "$R/usr/bin/curl"; do
  [ -f "$b" ] || continue
  ldd "$b" 2>/dev/null | awk '/=> \//{print $3} /^\//{print $1}' | sort -u | while read -r lib; do
    mkdir -p "$R$(dirname "$lib")"; cp "$lib" "$R$lib" 2>/dev/null || true
  done
done
[ -f "$R/lib64/ld-linux-x86-64.so.2" ] || { mkdir -p "$R/lib64"; cp /lib64/ld-linux-x86-64.so.2 "$R/lib64/" 2>/dev/null || true; }
# CA certs for catalog https (if curl was copied)
[ -f /etc/ssl/certs/ca-certificates.crt ] && { mkdir -p "$R/etc/ssl/certs"; cp /etc/ssl/certs/ca-certificates.crt "$R/etc/ssl/certs/"; }

( cd "$R" && find . | cpio -o -H newc --quiet ) | gzip -9 > "$WORK/initramfs.gz"
echo ">> initramfs: $(du -h "$WORK/initramfs.gz" | cut -f1)"

# --- EFI system partition image --------------------------------------------
ESP="$WORK/esp.img"; STAGE="$WORK/stage"; rm -rf "$STAGE"; mkdir -p "$STAGE/EFI/BOOT" "$STAGE/boot"
cp "$KERNEL" "$STAGE/boot/vmlinuz"; cp "$WORK/initramfs.gz" "$STAGE/boot/initramfs.gz"
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
menuentry "BC-250-X — Phase 1 Live (BC-250)" {
  linux /boot/vmlinuz console=tty0 console=ttyS0,115200 bc250x.live quiet loglevel=3
  initrd /boot/initramfs.gz
}
menuentry "BC-250-X — Phase 1 Live, verbose" {
  linux /boot/vmlinuz console=tty0 console=ttyS0,115200 bc250x.live loglevel=7
  initrd /boot/initramfs.gz
}
CFG
grub-mkstandalone -O x86_64-efi -o "$STAGE/EFI/BOOT/BOOTX64.EFI" "boot/grub/grub.cfg=$WORK/grub.cfg" --modules="part_gpt part_msdos iso9660 fat ext2 normal linux all_video search search_fs_file" 2>/dev/null \
 || grub-mkstandalone -O x86_64-efi -o "$STAGE/EFI/BOOT/BOOTX64.EFI" "boot/grub/grub.cfg=$WORK/grub.cfg"
ESP_KB=$(( ( $(stat -c%s "$STAGE/EFI/BOOT/BOOTX64.EFI") + $(stat -c%s "$KERNEL") + $(stat -c%s "$WORK/initramfs.gz") ) / 1024 + 8192 ))
dd if=/dev/zero of="$ESP" bs=1K count="$ESP_KB" status=none
mkfs.vfat -F 32 -n BC250XESP "$ESP" >/dev/null
mmd -i "$ESP" ::/EFI ::/EFI/BOOT ::/boot
mcopy -i "$ESP" "$STAGE/EFI/BOOT/BOOTX64.EFI" ::/EFI/BOOT/
mcopy -i "$ESP" "$STAGE/boot/vmlinuz" "$STAGE/boot/initramfs.gz" ::/boot/
echo ">> ESP: ${ESP_KB} KB"

# --- ISO ---------------------------------------------------------------------
cp "$ESP" "$STAGE/efi.img"
ISO="$OUT/bc250x-phase1-$(date +%Y%m%d).iso"
xorriso -as mkisofs -iso-level 3 -V BC250X -o "$ISO" \
  -eltorito-alt-boot -e efi.img -no-emul-boot -isohybrid-gpt-basdat "$STAGE" 2>&1 | tail -2
ls -lh "$ISO"
echo ">> DONE: $ISO"
echo ">> QEMU test: scripts/test-qemu.sh"
