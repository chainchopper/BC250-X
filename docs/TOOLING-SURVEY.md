# BC-250-X — Community Tooling Survey (Oct 23, 2026)

Terrell's direction: *provide every option a BC-250 owner would want, super
user-friendly* — so we surveyed the field before building our own. Sources:
the two projects Terrell supplied, plus the surrounding ecosystem. Everything
below was read from the projects' own READMEs/source on Oct 23 2026.

## The two supplied projects

### movacx/bc250-control-center — MIT, 212★, Python, actively maintained
A full desktop control center. The feature list is effectively the market's
answer to "what do users want for this board":

- Dashboard: CPU/GPU/cooling, per-core load, **GDDR6 temperature per chip**,
  BIOS version, power rails (needs an I2C hardware mod; app ships a photo guide)
- Charts + sensor view + CSV export
- GPU governor management (**Cyan**, with **Oberon** as alternative), safe
  frequency ranges, a "voltage laboratory"
- CPU tuning through the **SMU**, stability test, optional core unlock
- **Compute Units 24→40, with live state and boot state reported separately**
- Fans: manual PWM, temperature curves, persistent profiles, or hand-off to
  CoolerControl / fancontrol / fan2go
- Memory: VRAM size, ZRAM, ZSWAP, swap
- **BIOS update USB creation** (P3.00 Chipset, MeiMeiDXE v3, P5.00, P3.00,
  P2.00 — every file verified)
- Per-game upscaling: FSR4 INT8 via OptiScaler Client + HelixSR, with
  backup/restore of game files
- Per-distro system preparation in a built-in terminal; GFX1013 / ACPI /
  Mesa compatibility fixes; Dolby Digital 5.1 over HDMI; HDMI-CEC TV control
- Optional **Decky plugin** for Steam Game Mode; 30 languages; packages for
  Arch/CachyOS, Fedora/Nobara, Bazzite (rpm-ostree), SteamOS (beta),
  Ubuntu/Mint/Debian

**Verdict:** this is the high-water mark for the *installed-OS* experience.
BC-250-X should not clone it — Nirvana OS should **integrate** it (MIT) or
ship it as a first-class marketplace app, and `nirvana-config` (below) covers
the terminal-first equivalent. Its two UX rules are adopted project-wide:
**every hardware change is range-checked and confirmed before applying**,
and **live state vs boot state are always shown separately**.

### WinnieLV/bc250-cu-live-manager — license not stated in repo (checked: no LICENSE file)
A bash terminal UI for **runtime** WGP/CU dispatch via **UMR** register access:

- Reads the amdgpu boot topology (factory: 12 WGP = **24 CU**) and routes
  additional WGPs live — full dispatch = 20 WGP = **40 CU** — **no reboot,
  no kernel patch, fully reversible in-session**
- Custom WGP routing tables; save a table + systemd service to restore on boot
- Live dashboard + WGP table editor with honest state markers
  (driver+routed / SPI-routed-only / driver-on-but-unrouted)
- **Also unlocks the 2 disabled CPU cores through the SMU** (6c/12t → 8c/16t)
  at runtime — core unlock *without* flashing a BIOS
- Auto-installs `umr` if missing; root actions re-run via sudo with a reason

**Verdict:** the *better* CU mechanism for a friendly tool — live, granular,
reversible. Design reference + upstream link; no code bundled until its
license is clear. Its state-marker honesty is adopted into `nirvana-config`.

## The wider field (from the same sweep)

| Project | What it adds | BC-250-X take |
|---|---|---|
| duggasco/bc250-40cu-unlock | Kernel-patch route (`bc250_cc_write_mode=3`), **selective CU masking** (`amdgpu.disable_cu=SE.SH.WGP`), and a **per-WGP health test** (isolation boots + compute verify → mask file). 1.61× compute scaling verified | The health-test + masking pattern is the correct answer to the silicon lottery: unlock all → test each WGP → mask only the bad ones. Adopted as the CU flow in `nirvana-config`. License not stated in repo — design reference |
| bc250-collective/bc250_smu_oc | CPU overclock via SMU (`bc250-detect` / `bc250-apply`, auto-tuned voltage, systemd persistence); documented results to 3.9 GHz with cooling caveats | Nirvana-config "CPU tuning" section mirrors Control Center's SMU approach; OC stays an advanced, warned option |
| FilippoR cyan-skillfish-governor (SMU) + oberon | The governor layer: without it the GPU locks at 1500 MHz; safe-points config (e.g. 1500 MHz / 900 mV cap) | Already BC-250-X canon (kernel fragment + docs). nirvana-config exposes governor choice + safe-points |
| elektricM/amd-bc250-docs | The community knowledge base (governor, OC, cooling requirements) | Already cited across our docs |
| Forbidden-Darkness UEFI menu script | Firmware-menu + logo-variant model (see `docs/FLASH-AND-PRAY.md`) | Already integrated |

## The two "better options" this survey changes

1. **Core unlock does not require a BIOS flash.** The SMU runtime route
   (both supplied projects use it) is reversible and friendlier; Flash & Pray
   remains the *permanent* route. `nirvana-config` offers SMU first.
2. **CU unlock should be live + tested + masked, not one-shot.** UMR live
   routing for trying, the duggasco health-test for trusting, selective
   masking for keeping. A flat "40 CU on/off" is the worst of the options —
   it's what we had sketched; this replaces it.

## What users want — the consolidated option list

Dashboard/status · CU/WGP manager (live + boot) · CU health test + masking ·
core unlock (SMU + BIOS routes) · governor/clocks/voltage with safe ranges ·
CPU tuning/OC (warned) · fan curves/profiles · memory (VRAM carve, ZRAM,
GTT) · BIOS backup/flash/media · stability tests · per-game upscaling ·
distro prep + compat fixes · Game Mode (Decky) integration · updates.

That list is the specification for `nirvana-config` (`docs/NIRVANA-CONFIG.md`)
and the long-term Nirvana OS settings surface.
