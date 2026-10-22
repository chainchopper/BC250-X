# BC-250-X — Phase 1 Notes

**Gate:** an ISO that boots UEFI → kernel → BC-250-X init → menu/status, proven
in QEMU (OVMF) by an automated serial-console test. Not yet proven on a real
BC-250 — that is the Phase 1.1 bench step.

## What Phase 1 is (and is not)

| | Phase 1 (this) | Production path |
|---|---|---|
| Kernel | Ubuntu 24.04 `linux-image` binary (6.8 series — the OS/kernel family owner builds have run on real BC-250s, e.g. Ubuntu 24.04.5 AI builds) | Custom kernel in the known-good range (6.12–6.14 LTS + gfx1013/oberon), via the Buildroot tree (`scripts/build-iso.sh`) |
| Userspace | Hand-rolled busybox initramfs: Phase 1 init + menu + the real `bc250x` CLI + catalog JSONs | Native UI (Slint/DRM) port of the prototype |
| Boot | GRUB EFI standalone (BOOTX64.EFI) on a FAT ESP, El Torito + isohybrid GPT | systemd-boot UKI (per ARCHITECTURE.md) |
| Assembler | `scripts/build-iso-phase1.sh` (minutes, no compilation) | `scripts/build-iso.sh` (Buildroot, hours) |

Nothing in Phase 1 flashes anything. BIOS write paths stay gated exactly as
specified in SAFETY.md and arrive in Phase 2.

## Build & test

```bash
# Host needs: qemu-system-x86 ovmf xorriso grub-efi-amd64-bin busybox-static
#             cpio mtools dosfstools linux-image-generic kmod
./scripts/build-iso-phase1.sh        # -> output/bc250x-phase1-<date>.iso
python3 scripts/test-qemu-drive.py   # boots it, picks menu "1", checks bc250x status output
```

The QEMU test drives the serial console: it waits for the `BC250X_BOOT_OK`
marker, the menu prompt, then runs menu item 1 and asserts `bc250x status`
prints core/kernel lines. A passing run is the Phase 1 gate.

## Known Phase 1 limits

- bc250x `status` in the initramfs has no `dmidecode`/`sensors` binaries yet —
  it reads /proc + DMI sysfs (the script already falls back gracefully).
- Network in the test VM is best-effort DHCP (udhcpc); catalog fetch works on
  real LAN, not asserted in the QEMU test.
- GRUB menu timeout 5 s; serial + VGA consoles both enabled
  (`console=tty0 console=ttyS0,115200`).
