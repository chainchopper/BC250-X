# BC-250-X — Product Specification v0.1

Owner: Fanalogy · Target hardware: **AMD BC-250 only** · Date: 2026-10-20

## 1. Product in one line

A UEFI-bootable live front-end (USB / ISO / NetBoot) that gives a BC-250
owner a beautiful, safe GUI for system info, BIOS backup & flash, curated
OS install, diagnostics, and direct boot into an installed OS — plus a
full CLI for manual work.

## 2. Verified hardware baseline

All values checked 2026-10-20 against community docs and reporting
(amd-bc250-docs / elektricM, Tom's Hardware Aug 2026 feature, multiple
owner repos). Where sources disagree, BC-250-X displays the *detected*
value at runtime, never the spec-sheet value.

| Item | Stock | After community BIOS / unlock | Notes |
|---|---|---|---|
| APU | Cyan Skillfish, gfx1013, PCI 0x13FE | — | PS5-derived |
| CPU | Zen 2, 6 cores / 12 threads | 8 / 16 via BIOS config | Dashboard shows detected count |
| GPU | 24 CU (1536 SP) | 32 / 36 / 40 CU driver unlock, per-board stability | Never forced by BC-250-X |
| Memory | 16 GB GDDR6, 256-bit, unified | — | No DIMM slots |
| VRAM carve | fixed stock | **512 MB dynamic (recommended)** | Set in modded BIOS |
| Storage | M.2 NVMe PCIe 2.0 x2 | — | ~1 GB/s ceiling |
| Display | DisplayPort (passive DP→HDMI OK) | — | Active adapters unreliable |
| Network | Gigabit Ethernet | USB Wi-Fi dongle only | **No onboard Wi-Fi on BC-250** |
| Power | 8-pin PCIe, ~300 W PSU recommended | — | 220 W board nameplate |
| BIOS chip | 16 MB: W25Q128JVSQ **or** MX25L12835F / MX25L12873F, SOIC-8 | — | Flash whitelist |
| SuperIO chip | 512 KB MX25L4005A | — | **Never flash — bricking risk** |
| BIOS | Stock P5.00 / P3.00 | **Modded P3.00 Chipset Menu = proven target** | P5.00_clv is experimental, listed with warning |
| Required settings | — | IOMMU Disabled, VRAM 512 MB dynamic, CMOS clear after flash | Checked on Dashboard with fix guidance |

Kernel compatibility (hard-coded guardrail in the OS catalog):
**Good:** 6.12–6.14 LTS, 6.15.7–6.17.7, 6.17.11+ · **Broken on BC-250:**
6.15.0–6.15.6, 6.17.8–6.17.10 (amdgpu discovery / GPU-init failures).
GPU clock control is the community **oberon** governor; core cap 1500 MHz
recommended for the CU unlock.

## 3. Boot chain

```
UEFI firmware
  -> systemd-boot (themed, 5 s, BC-250-X default)
       -> Unified Kernel Image: custom kernel (known-good LTS + gfx1013/oberon patches)
            + initramfs (Buildroot)
              -> bc250x-init: mounts catalog cache, probes hardware
                   -> bc250x-ui (DRM/KMS framebuffer, keyboard + mouse + gamepad nav)
                   -> fallback: bc250x CLI shell on tty2 (always available, Ctrl+Alt+F2)
  NetBoot variant: firmware -> iPXE (bc250x-ipxe.efi) -> boot.ipxe -> same UKI over HTTP
```

Boot target: splash in < 3 s after kernel, full dashboard in < 10 s on NVMe-less USB boot.

## 4. Screens & required behaviour

### 4.1 Dashboard (home)
- Live (1 s refresh): CPU temp (k10temp), GPU temp/power/clock (amdgpu hwmon),
  CPU load per core, memory used (unified pool + carve shown separately),
  fan RPM where readable, uptime, board power estimate with “uncalibrated sensor” note.
- Identity block: board model, BIOS version + date + ROM ID (DMI), BIOS chip ID (probe, read-only),
  CPU cores/threads detected, GPU CU detected, kernel version, BC-250-X version.
- Health flags: IOMMU enabled → red flag + why; VRAM ≠ 512 MB dynamic → amber;
  broken-kernel range → red; no verified BIOS backup found → amber “Back up your BIOS”.
- Buttons: Boot OS · BIOS · Install OS · Diagnostics · Network · CLI · Reboot · Shutdown.

### 4.2 Boot OS
- Enumerate: EFI Boot Manager entries (`efibootmgr`), systemd-boot entries on all ESPs,
  GRUB installs, Windows Boot Manager if present.
- Each entry shows disk, partition, OS name/icon where detectable.
- Action = set BootNext + reboot (reversible, one-shot). “Boot directly” never edits
  the permanent boot order unless the user ticks that box explicitly.

### 4.3 BIOS — Backup
- Probe chip read-only first; abort if ID is the SuperIO chip or size ≠ 16 MB.
- Read twice → SHA-256 both → must match → save as
  `BC250-backup-<biosver>-<date>-<sha8>.bin` to chosen destination
  (USB / NVMe data partition / network upload if configured).
- Show hash on screen + write a `.json` sidecar (board DMI, chip, date, tool versions).

### 4.4 BIOS — Flash
Three gates, all mandatory, UI will not skip:
1. **Image gate** — size == 16,777,216, SHA-256 matches catalog entry (remote)
   or user-confirmed hash (local), ROM ID matches BC-250 family.
2. **Backup gate** — a verified backup from §4.3 exists in this session or on media.
3. **Confirm gate** — user types `FLASH`, AC-power warning acknowledged,
   “do not power off for up to 15 minutes” shown (real community guidance).
- Execution: stage image + generated `Flash.nsh` on the ESP/USB, reboot into a
  dedicated **Flash Mode** that runs the proven community flow:
  `AfuEfix64.efi` + `amdvbflash.efi` (for VBIOS region where applicable),
  log everything to `bc250x-flash.log` on USB.
- After flash: wizard forces the **CMOS-clear procedure** (battery out 60 s),
  then first-boot verification (BIOS version read-back, settings checklist:
  IOMMU off, VRAM 512 MB dynamic, core config).
- Recovery path documented in-app: J4004 header + CH347 (native 3.3 V) +
  `flashrom -p ch341a_spi`, with the two-chip warning on the same screen.

### 4.5 Install OS
- Source: live signed catalog (`catalog/os.json`) — GitHub raw primary,
  Fanalogy mirror secondary, verified cache offline fallback.
- Each entry: name, version, size, SHA-256, BC-250 kernel status, GPU/oberon
  included?, best-for tag, download URL, signature status.
- Actions per entry: **Download** (resumable, hash-verified) →
  **Write to USB** (destructive, device picker excludes the BC-250-X boot stick by default) or
  **Install to NVMe** (advanced, full-disk wipe warning, typed confirm).
- **Nirvana OS:** entry present from v0.1, `status: coming_soon`, no download
  button until Fanalogy publishes an image + hash to the catalog.

### 4.6 Diagnostics
- Quick (2 min): sensors sweep, NVMe SMART + short read test, memory quick pattern,
  display EDID, network ping/DNS, GPU presence + CU count.
- Full: memtest86+ (EFI, reboot-into), stress-ng CPU 10 min, GPU stress (vkmark / gpu-burn class),
  fio NVMe benchmark, thermal soak graph (temp vs. time, throttling events).
- Every run saves a timestamped report (`.txt` + `.json`) to USB / data partition.

### 4.7 Network
- Ethernet: DHCP auto, shows IP/gateway/DNS, link speed.
- Wi-Fi: **USB dongles only** — bundled firmware for common Realtek / MediaTek / Atheros
  USB chipsets; scan → SSID list with signal → WPA2/WPA3 password entry (on-screen keyboard) → iwd/wpa_supplicant connect.
  If no dongle is detected, screen says so plainly instead of showing an empty spinner.
- Used by: catalog refresh, BIOS/OS downloads, diagnostics upload (opt-in only).

### 4.8 CLI Mode
- Full shell (tty2 or in-UI terminal) with: `flashrom`, `efibootmgr`, `dmidecode`,
  `sensors`, `nvme`, `smartctl`, `stress-ng`, `memtester`, `curl`, `ip`, `iw`, plus the
  wrapper: `bc250x status | backup | verify <file> | flash <file> | diag | catalog`
  (`bc250x flash` enforces the same three gates; `--i-know` does not exist).

## 5. Live catalog contract

See `catalog/*.json` in this repo — that *is* the contract.
Rules: semantic versions, SHA-256 lowercase hex, sizes in bytes,
`bc250_chip_ids` whitelist on every BIOS entry, `kernel_status` on every OS entry,
entries are only ever *added/marked*, never silently edited (a changed hash = new version).

## 6. Non-goals (v1)

- No support for any board other than BC-250. Probes that don't match = refuse + explain.
- No Windows-based flashing, no in-Windows updater.
- No forced CU/CPU unlocking. BC-250-X *detects and reports*; unlocking stays a BIOS/driver choice.
- No telemetry by default. Reports leave the machine only when the user sends them.

## 7. Open decisions for Fanalogy (see ROADMAP for the ask)

1. ~~Catalog hostnames/org~~ — DECIDED Oct 20 2026: repo `chainchopper/BC250-X` (public), mirror `downloads.fanalogy.com`. OS lineup also decided: **Bazzite = default install**, plus **Ubuntu 26.04 LTS** and **SteamOS** (both labelled Experimental on BC-250 — Ubuntu 26.04 ships kernel 7.0, outside the verified matrix; BC-250 is not on Valve's supported list).
2. Which Fanalogy BIOS builds to list first (recommendation: P3.00 Chipset Menu as “Recommended”, stock P3.00/P5.00 as “Recovery”, P5.00_clv as “Experimental — warning”).
3. Nirvana OS image ETA + whether its marketplace/agent stack ships in the base image or as a first-boot download.
