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
  menu script as Phase 1, the real `bc250x` CLI, the catalog JSONs in
  `/usr/share/bc250x/`, kmod, curl (for `bc250x catalog`), and the amdgpu
  linux-firmware blobs so the image is ready for a real board.
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

- **Deferred to Phase 2 (BIOS flows):** flashrom, efibootmgr, minisign
- **Deferred to diagnostics work:** dmidecode, lm_sensors, smartmontools,
  nvme-cli, fio, stress-ng, memtester
- **Deferred to network work:** iwd (busybox udhcpc covers the bench test)
- **Dropped by design:** systemd (busybox init is the live-system design),
  squashfs rootfs (the initramfs *is* the rootfs)

## Gate

The production gate is the same as Phase 1, one notch stricter: the ISO
boots in QEMU/OVMF, the init prints `BC250X_BOOT_OK kernel=6.12.x` —
proving the *custom* kernel booted, not the Phase 1 distro kernel — the
menu runs `bc250x status`, and the machine powers off clean.
Log: `build/qemu-drive-prod.log`.

**Result — Oct 23, 2026: PASS.** `output/bc250x-prod-20261023.iso`
(137 MB, SHA-256
`b57d8a36631e47e9b0f6650b5abb677ac65be5207436625caf1973880e2817d1`)
booted in QEMU/OVMF with `BC250X_BOOT_OK kernel=6.12.0`; the menu ran
`bc250x status` (DMI board/BIOS, core count, kernel guardrail line) and
powered off clean. DHCP networking also came up in the VM. Built-kernel
config verified post-build: `CONFIG_DRM_AMDGPU=y`, SI/CIK off,
`CONFIG_SENSORS_K10TEMP=y`, NVMe and EFIVAR_FS on; the rootfs carries
the full amdgpu firmware set including the `cyan_skillfish2_*` blobs.
Remaining gate, unchanged: boot on a real BC-250 (see
`docs/BENCH-TEST.md`).
