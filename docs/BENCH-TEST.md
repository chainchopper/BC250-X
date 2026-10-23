# BC-250-X — Real-Board Bench-Test Checklist

**Purpose:** capture everything the Phase 1 ISO proves (or breaks) on real
BC-250 hardware in one pass. QEMU proved the boot chain; only real silicon
proves the board likes it. This is the Phase 1.1 gate.

**Safety first:** nothing in the Phase 1 ISO can flash anything — BIOS write
paths stay gated per `docs/SAFETY.md` and arrive in Phase 2. This test is
read-only. The board has **two** SPI chips: the 16 MB BIOS chip
(W25Q128JVSQ / MX25L128*) and a 512 KB SuperIO chip (MX25L4005A) — the latter
is never to be flashed, ever. You will not touch either today.

---

## 1. Write the USB (do this first, from a Linux/macOS host)

- [ ] Verify the ISO before writing it:
  ```bash
  cd ~/workspace/your_files
  sha256sum -c bc250x-phase1-20261021.iso.sha256
  ```
  Must print `OK`. If it doesn't, stop — do not boot a corrupt image.
- [ ] Write to USB (the ISO is isohybrid, so `dd` works):
  ```bash
  sudo dd if=bc250x-phase1-20261021.iso of=/dev/sdX bs=4M status=progress oflag=sync
  ```
  Replace `/dev/sdX` with the USB stick (check with `lsblk` first). Or use
  Balena Etcher. Eject cleanly.

## 2. BIOS settings (one-time, before first boot)

- [ ] Boot mode: **UEFI only**, CSM/Legacy disabled (the ISO boots via
      BOOTX64.EFI on a FAT ESP; legacy boot will not find it).
- [ ] Secure Boot: **disabled** (the EFI binary is not signed).
- [ ] Note — do NOT change IOMMU for this test; the disabled-IOMMU rule
      applies to installed-OS boots later, not to the live ISO.

## 3. Boot (capture with photos or a serial log)

- [ ] Boot the USB from the board's boot menu (F7 / F11 / Del — varies).
- [ ] GRUB menu appears. Note the timeout: expected **5 s** (`grub.cfg`
      default). Record the exact GRUB entries shown.
- [ ] Pick the default entry. Both consoles are enabled
      (`console=tty0 console=ttyS0,115200`), so the VGA screen and serial
      should show the same boot.
- [ ] Watch for the `BC250X_BOOT_OK` marker — that's the automated QEMU
      gate's success signal. Note the wall-clock time from GRUB to menu.

## 4. The menu + `bc250x status` (the core of the gate)

- [ ] Photo or transcript of the full menu screen.
- [ ] Run **menu item 1** (the QEMU test does exactly this). Record the
      complete output of `bc250x status`, in particular:
  - [ ] CPU `model name` line — does it name the BC-250's AMD APU?
  - [ ] `Cores: N  CPUs online: N` — stock BC-250 is **6c/12t**; a board
        with the modded P3.00 Chipset BIOS shows **8c/16t**. Record which
        you see.
  - [ ] `Board:` / `BIOS:` version + date lines (DMI sysfs). Note: the
        Phase 1 initramfs has no `dmidecode` binary, so this comes from
        `/sys/class/dmi/id` — if a line is blank, that's a known limit,
        not a failure. Record which fields read blank.
  - [ ] Any `hwmon` temp / power lines (uncalibrated). Note: `sensors`
        is not present in Phase 1; temps come from hwmon sysfs.
  - [ ] `Kernel:` line — expect **6.8.x** (the distro-kernel shortcut).
        Anything in 6.15.0–6.15.6 or 6.17.8–6.17.10 would trip the guardrail.
- [ ] Keyboard check: can you navigate the menu and type? (QEMU used
      serial; real USB keyboards sometimes behave differently.)

## 5. Optional-but-valuable extras

- [ ] Run `bc250x catalog` (needs DHCP). Does it fetch `bios.json`,
      `os.json`, `tools.json` from the live GitHub catalog? Network was
      best-effort in QEMU; a real LAN is the first real test.
- [ ] Run `bc250x diag` and record the output.
- [ ] If the board has a BMC/serial header, capture a full serial log —
      it makes any failure debuggable in one pass.

## 5b. Shell captures — the GPU (the QEMU-blind spot)

QEMU has no gfx1013, so what the kernel's amdgpu driver does on the *real*
Cyan Skillfish is the one thing only this session can tell us. Open the
shell (menu item 3) and run:

- [ ] `dmesg | grep -i amdgpu` — **photo this.** Does amdgpu find and
      initialize the GPU without fatal errors (no `amdgpu_discovery_init`
      failure, no GPU hang)?
- [ ] `ls /sys/class/drm` — record which `card*` entries exist (a `card0`
      here means the GPU came up as a DRM device).
- [ ] `grep -c processor /proc/cpuinfo` — cross-check against the status
      core count from §4.
- [ ] `dmesg | grep -iE 'error|fail'` — record anything that isn't
      obvious noise.
- [ ] Exit the shell and finish with **menu item 5** — does the board
      power off cleanly from the menu?

## 6. What to send back

Four things close the gate:

1. The full `bc250x status` output (photo or pasted text).
2. A photo of the menu screen.
3. A photo of the `dmesg | grep -i amdgpu` output from §5b — the GPU
   verdict QEMU could never give us.
4. One line on what differed from QEMU, if anything — boot time,
   blank DMI fields, missing hwmon, keyboard quirks, network result.

If any step fails, note *where* it failed (GRUB? kernel? init? menu?)
and the last line on screen. Do not change anything on the board to
"make it work" — the point is to learn what the ISO does, not to fix
the board.
