# BC-250-X — Architecture

Design principle: **assemble proven open-source parts, write only the
BC-250-specific glue.** Nothing in the stack below is speculative — every
component is a shipping project with a license that allows this use.

## Stack map (requested feature → real component)

| Requested feature | Component | Why this one |
|---|---|---|
| Boots in UEFI mode | **systemd-boot** + EFI-stub kernel (UKI) | Tiny, themeable, reads simple text entries, native BootNext handling. rEFInd kept as fallback theme in `efi/` notes — prettier, heavier. |
| Custom kernel | **Linux LTS (known-good range only)** + BC-250 patch set (amdgpu gfx1013, oberon governor) | Community-proven on this exact board; broken version ranges are excluded in `kernel/` fragments |
| Beautiful UI fast at boot | Native app on **DRM/KMS framebuffer** (Rust + Slint, or C + LVGL) — no X/Wayland | Boots in seconds, one binary, gamepad/keyboard/mouse nav. The HTML prototype in `ui-prototype/` is its pixel/state spec. |
| Tiny live system / ISO | **Buildroot** (BR2_EXTERNAL tree in this repo) | Reproducible ~200 MB image, fastest path to a maintainable ISO; Yocto/mkosi rejected as heavier for a single-board target |
| ISO, hybrid USB | **xorriso** isohybrid + ESP image | Standard, Ventoy/Rufus/dd compatible |
| NetBoot compatible | **iPXE** (`ipxe/boot.ipxe`) | The netboot standard; also chainloadable from netboot.xyz |
| System stats / temps | `/sys/class/hwmon` (k10temp, amdgpu), `lm-sensors`, DMI via `/sys/class/dmi` + `dmidecode` | Direct kernel interfaces, no daemon needed |
| BIOS info | DMI/SMBIOS + read-only `flashrom -p internal` probe | Probe is read-only in UI; write path is separate (§ below) |
| BIOS backup | flashrom internal read (whitelisted 16 MB chips only, double-read + hash) **or** AfuEfi `/O` in Flash Mode | Two independent paths; both verified against the chip whitelist |
| BIOS flash (remote + local) | **Staged AfuEfix64 UEFI-shell flow** (the community-proven P3.00 method), automated by generated `Flash.nsh`; flashrom for external-programmer recovery | This board's stock method is EFI-shell Afu, *not* internal Linux flashing — BC-250-X automates what is proven instead of inventing a riskier path |
| Network LAN | Kernel drivers + DHCP (systemd-networkd / udhcpc) | Board Ethernet just works |
| Network Wi-Fi | **iwd / wpa_supplicant** + bundled USB-dongle firmware (linux-firmware: Realtek, MediaTek, Atheros USB) | Board has no onboard Wi-Fi; dongle support is the honest scope |
| Boot installed OS | `efibootmgr` BootNext + systemd-boot entry scan | One-shot, reversible |
| OS downloads / install | `curl` (resumable) + hash verify + raw writer (`dd` wrapper with device guards) | No custom download protocol to audit |
| Live BIOS/OS/tool lists | **Static signed JSON** on GitHub raw + Fanalogy mirror, **minisign** signatures | Static hosting = no server to run, works from GitHub alone; signature = trust without TLS-only assumptions |
| Diagnostics | **memtest86+** (EFI), **stress-ng**, **smartmontools**, **nvme-cli**, **fio**, vkmark-class GPU test | All standard, all scriptable, reports in txt+json |
| CLI mode | BusyBox + bash on tty2, `bc250x` wrapper script (`scripts/bc250x`) | Same safety gates as the GUI |

## Trust & update model

- Catalog JSON is signed (minisign). Public key ships in the ISO (`config/catalog.pub` placeholder).
- BIOS/OS payloads are trusted by **hash in the signed catalog**, not by download host.
- Local user files are trusted only after the user confirms the shown SHA-256 — and still must pass size + ROM-ID gates.
- BC-250-X itself is not self-updating in v1; a new ISO is the update. (Catalog data updates live, which is the part that changes weekly.)

## Data flow — flash from network (the headline flow)

```
UI: BIOS > Fanalogy BIOS list (from signed catalog)
  -> download .ROM to RAM-disk staging   (progress, resumable)
  -> verify SHA-256 == catalog          (fail = delete, no flash button)
  -> verify size + ROM ID + chip probe
  -> require/create verified backup     (§ SPEC 4.3)
  -> typed FLASH confirmation
  -> write image + Flash.nsh to ESP staging, set BootNext=FlashMode
  -> reboot: UEFI shell runs Flash.nsh -> AfuEfix64 (log to USB)
  -> reboot: BC-250-X first-boot wizard -> CMOS-clear check -> settings verify -> report
```

## What is code today vs. staged

- **Today (v0.3 in this repo):** full spec, signed-catalog schemas with real
  community BIOS/OS entries, Buildroot external tree skeleton, kernel config
  fragments with the known-good/broken guardrails, iPXE script, Flash.nsh
  template, `bc250x` CLI wrapper (status/backup/verify functional in a Linux
  shell; flash intentionally routed through the gated Flash-Mode staging),
  build scripts, the clickable UI prototype that fixes the design — **plus the
  Phase 1 bootable ISO** (`scripts/build-iso-phase1.sh`: Ubuntu 24.04 kernel
  binary + busybox initramfs carrying the real `bc250x` CLI and catalog
  files), **boot-verified in QEMU/OVMF** by the automated serial drive test
  (`scripts/test-qemu-drive.py`). See `docs/PHASE1.md`.
- **Next build steps:** boot the Phase 1 ISO on a real BC-250 (the remaining
  Phase 1 gate); finish the Buildroot defconfig → custom-kernel production
  ISO; port the prototype screens 1:1 to the native Slint UI.

Honesty note: the Phase 1 ISO is a boot-chain proof, not the production
image — it uses a distro kernel binary, and it has not yet booted on real
BC-250 hardware. The docs say so plainly, because a fake claim helps nobody.
