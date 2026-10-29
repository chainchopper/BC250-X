# BC-250-X — Production build (Buildroot + custom kernel)

Phase 1 proved the boot chain with a shortcut: a distro kernel binary
(Ubuntu 24.04, 6.8) plus a hand-rolled initramfs. This is the production
path that replaces the shortcut:

- **Buildroot 2025.02** with the project's external tree
  (`buildroot-external/`, `bc250x_defconfig`)
- **Custom kernel 6.12.0 LTS** — the top of the known-good BC-250 range
  (see `kernel/bc250x-kernel.fragment` for the guardrail matrix: 6.15.0–6.15.6
  and 6.17.8–6.17.10 are broken on this APU). Config = x86_64 arch defconfig
  with the BC-250 fragment applied on top (`CONFIG_DRM_AMDGPU=y` for
  Cyan Skillfish / gfx1013, SI/CIK off, k10temp, NVMe, EFIVAR_FS, USB Wi-Fi
  module families).
- **Prebuilt Bootlin x86-64 glibc toolchain** (external) — no toolchain
  compile, which keeps the build feasible on small machines.
- **Busybox initramfs** (`rootfs.cpio.gz`): PID 1 is the same `/init`
  menu script as Phase 1, the real `bc250x` CLI (status / backup /
  verify / flash / pray), `nirvana-config`, the catalog JSONs in
  `/usr/share/bc250x/`, kmod, curl (for `bc250x catalog`), and the amdgpu
  linux-firmware blobs so the image is ready for a real board.

## Flash-test payload (bundled in the image)

This ISO is the flash-test image: the rootfs carries the whole Flash Mode
payload under `/usr/share/bc250x/` —

- `efi/bc250x-menu.nsh` — the BC-250-X UEFI-shell menu (from
  `efi/menu/bc250x-menu.nsh`)
- `efi/Flash.nsh.template` — the AfuEfix64 flash script template
- `payload/BC250_3.00_CHIPSETMENU.ROM` and `payload/BC250_3.00.ROM` — the
  genuine community ROMs (modded P3.00 Chipset Menu + stock P3.00, from
  gitlab.com/TuxThePenguin0/bc250-bios), 16,777,216 bytes each.

The ROMs are **not in git**: they are build-time downloads placed in
`build/payload/`, and `buildroot-external/board/bc250x/post-build.sh`
injects them into the rootfs during the build (and refuses any file
that isn't exactly 16 MiB). An image built without `build/payload/`
ships without ROMs and the post-build log says so. Nothing in the boot
path flashes anything — flashing stays behind the `bc250x` gates
(verified backup, size + hash check, typed confirmation) exactly as
`docs/SAFETY.md` and `docs/FLASH-AND-PRAY.md` specify.

## Netboot artifacts

Beside the ISO, `scripts/build-iso.sh` emits the raw boot files to
`output/netboot/`:

- `vmlinuz` — the same custom 6.12.0 kernel
- `rootfs.cpio.gz` — the same initramfs/rootfs
- `SHA256SUMS`

Serve that directory over any static HTTP server (for a bench test:
`python3 -m http.server 8080 --directory output/netboot`) and point
`ipxe/boot.ipxe` at it — the script's `base` variable defaults to
`https://downloads.fanalogy.com/bc250x/netboot`. Boot is kernel+initrd
style (the initramfs is the rootfs; no ISO sanboot, no second rootfs
download). `scripts/build-ipxe.sh` can embed the script into a
bootable `ipxe.efi`.
- **ISO packaging** reuses the Phase 1-proven pattern (GRUB standalone EFI
  on a FAT ESP, hybrid El Torito) — Buildroot's own iso9660 target is
  BIOS-oriented and is not used.

## Build

```bash
./scripts/build-iso.sh        # -> output/bc250x-prod-<date>.iso (+ .sha256)
python3 scripts/test-qemu-drive-prod.py   # QEMU/OVMF gate: expects kernel=6.12.x
```

`scripts/build-iso.sh` runs the whole pipeline: fetch Buildroot →
`bc250x_defconfig` → `make` → package ISO from `output/images`
(`bzImage` + `rootfs.cpio.gz`).

## Trimmed / deferred

The skeleton defconfig's Phase 2 payload was deliberately dropped from
this build to keep it lean and fast to iterate on; none of it is needed
for the boot gate, and all of it returns with the phases that use it:

- **Deferred to Phase 2 (BIOS flows):** efibootmgr, minisign
  (flashrom graduated in v0.4.1 — see below)
- **Deferred to diagnostics work:** dmidecode, lm_sensors, smartmontools,
  nvme-cli, fio, stress-ng, memtester
- **Deferred to network work:** iwd (busybox udhcpc covers the bench test)
- **Dropped by design:** systemd (busybox init is the live-system design),
  squashfs rootfs (the initramfs *is* the rootfs)

## Gate

The production gate is the same as Phase 1, one notch stricter: the ISO
boots in QEMU/OVMF, the init prints `BC250X_BOOT_OK kernel=6.12.x` —
proving the *custom* kernel booted, not the Phase 1 distro kernel — the
menu runs `bc250x status`, the shell runs a non-destructive
`bc250x verify` on the bundled payload ROM (size gate + SHA-256), and
the machine powers off clean.
Log: `build/qemu-drive-prod.log`.

**Result — Oct 23, 2026: PASS (full gate, incl. flash payload).**
`output/bc250x-prod-20261023.iso` (146 MB, SHA-256
`3d19b435834778b6db24f3782a511530e23ff5f8344329cdbf4b28ff69c21be7`)
booted in QEMU/OVMF with `BC250X_BOOT_OK kernel=6.12.0`; the menu ran
`bc250x status` (DMI board/BIOS, core count, kernel guardrail line);
the shell ran `bc250x verify` on the bundled
`/usr/share/bc250x/payload/BC250_3.00_CHIPSETMENU.ROM` — size gate OK,
SHA-256 `48fbe5d366e6a56e2fdffdca848426216ba1f083610dab63db89d2f4e6c940b5`,
matching the source ROM — and the machine powered off clean. DHCP
networking also came up in the VM. Built-kernel config verified
post-build: `CONFIG_DRM_AMDGPU=y`, SI/CIK off,
`CONFIG_SENSORS_K10TEMP=y`, NVMe and EFIVAR_FS on; the rootfs carries
the full amdgpu firmware set including the `cyan_skillfish2_*` blobs,
both payload ROMs, the UEFI menu + Flash.nsh template, and
`nirvana-config`. Netboot pair (`vmlinuz` + `rootfs.cpio.gz` +
`SHA256SUMS`) emitted to `output/netboot/`. Remaining gate, unchanged:
boot on a real BC-250 (see `docs/BENCH-TEST.md`).

## v0.4.1 changes (Oct 28, 2026)

flashrom is now the flasher (the AfuEfix64 dependency is gone):

- **Defconfig:** `BR2_PACKAGE_FLASHROM=y` (flashrom 1.5.1) +
  `BR2_PACKAGE_PCIUTILS=y` (libpci for the internal programmer) +
  `BR2_PACKAGE_LIBUSB=y`. The image ships `/usr/sbin/flashrom`; the
  current `scripts/bc250x` (flash write flow, `pray` v2, `flashmode`)
  is packaged from the tree — the rootfs-overlay copies of `bc250x`,
  `bc250x-menu.nsh` and `Flash.nsh.template` were re-synced to their
  canonical sources (they had gone stale in v0.4.0).
- **Live marker:** `/init` now creates `/run/bc250x-live` at boot. The
  CLI's write commands check for it (`require_live`) — this initramfs
  *is* the live system, so it proves it once, at boot.
- **Flash Mode boot entry:** GRUB gains a third entry, "BC-250-X Flash
  Mode" — same kernel/initrd plus `bc250x.flashmode=1`. When the flag
  is present, `/init` runs `bc250x flashmode` on the console before the
  menu. Note: the ESP is not mounted in this initramfs, so flashmode
  currently reports "no staged image at
  /boot/efi/bc250x-flash/BC250X.ROM" and exits clean — mounting the ESP
  in init is the follow-up that makes GUI-staged flashes reachable here.
- **Gate:** `scripts/test-qemu-drive-v041.py` (PASS A–F; log
  `build/qemu-drive-v041.log`) plus
  `scripts/test-qemu-pray-i440fx.py` (log `build/qemu-pray-i440fx.log`).

**Result — Oct 28, 2026: PASS.** `output/bc250x-prod-20261028.iso`
(142 MB, SHA-256
`abdee8d4c25ad675ac5a8e935d15788dff61713e1ac2de4ac0599efdc93bebe6`):
PASS A `BC250X_BOOT_OK kernel=6.12.0`; PASS B menu + `bc250x status`;
PASS C `bc250x verify` on the bundled P3.00 payload → `48fbe5d3…`
(byte-identical); PASS D `flashrom v1.5.1` present at
`/usr/sbin/flashrom`, internal probe executes; PASS F Flash Mode boot →
`bc250x flashmode` reported no staged image, menu reached. PASS E has a
QEMU footnote: on q35, QEMU's emulated ICH9 SPI window is misdetected by
flashrom as a 256 kB ST M95M02 whose transactions all error out, so
pray's backup read grinds instead of failing fast — it still cannot and
did not pass its gates (dual 16 MB read + typed `PRAY`); no Step 2/3,
no write. On i440fx/PIIX3 (`-machine pc`), where there is no emulated
SPI at all, PASS E holds exactly as specified: pray passed
`require_live` (live marker works), reached the verified-backup step,
flashrom reported "No EEPROM/flash device found", and pray exited there
with the shell responsive.
