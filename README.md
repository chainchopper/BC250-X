# BC-250-X — by Fanalogy

**An easy, beautiful, bootable front-end built only for the AMD BC-250.**

Plug in a USB (or netboot it), it boots in UEFI mode into a custom kernel,
and you get a full-screen UI that shows what your board is doing, backs up
and flashes BIOS safely, installs a curated OS, runs diagnostics — and
boots straight into your installed OS when you just want to play / work.

> This is **not** a generic PC tool. Every check, limit, and default in
> BC-250-X is hard-coded for BC-250 hardware. That is what makes it safe
> and simple.

![Status](https://img.shields.io/badge/status-v0.3%20%C2%B7%20Phase%201%20ISO%20boots%20%C2%B7%20QEMU%20verified-brightgreen)
License: GPL-3.0 (UI + scripts) — bundled tools keep their own licenses, see `docs/COMPONENTS.md`

---

## What it does

| Screen | What you get |
|---|---|
| **Dashboard** | Live CPU/GPU temps, clocks, power, fan, cores/threads actually enabled, CU count, RAM/GDDR6 split, VRAM carve, NVMe health, BIOS version + chip ID, network status |
| **Boot OS** | Auto-detects installed OSes on NVMe/USB (EFI entries + Linux installs) and boots one directly — one click, set as next-boot and reboot cleanly |
| **BIOS** | One-click **Backup** (read twice, hashes must match, saved to USB/NVMe/cloud) • **Flash** from Fanalogy catalog, from network, or browse local files — with 3 safety gates before anything writes |
| **Install OS** | Curated OS list pulled **live** from GitHub / Fanalogy servers — download, verify SHA-256, write to USB or install to NVMe. **Default install: Bazzite** (the given). Also listed: **Nirvana OS** (Coming Soon, flagship), **Ubuntu 26.04 LTS** and **SteamOS** — both flagged Experimental on BC-250 until a bench board verifies them (see catalog notes) |
| **Diagnostics** | Memtest, CPU stress (stress-ng), GPU stress, NVMe speed + SMART, thermal soak, display/network tests — with pass/fail summary you can save |
| **Network** | Wired Ethernet (DHCP, instant) + USB Wi-Fi dongles (scan, pick SSID, password, connect). No onboard Wi-Fi exists on BC-250 — see `docs/SPEC.md` |
| **CLI Mode** | A real shell with `bc250x` commands for backup / flash / verify / diag — for users who want to do it by hand |

## Download sources (live, signed)

BC-250-X never bakes a stale BIOS/OS list into the ISO. On boot with network it fetches:

```
https://raw.githubusercontent.com/chainchopper/BC250-X/main/catalog/bios.json
https://raw.githubusercontent.com/chainchopper/BC250-X/main/catalog/os.json
https://downloads.fanalogy.com/bc250x/catalog/   (mirror, same signed files)
```

Every entry carries size + SHA-256 + compatible board/chip IDs. Every catalog
is minisign-signed. If signature or hash fails, the item is shown but
**Flash / Install is disabled** — no exceptions. Offline? The last verified
catalog is cached, and local-file browsing always works.

Repo: **github.com/chainchopper/BC250-X** (public — the booted ISO fetches these raw URLs unauthenticated). Mirror host is `downloads.fanalogy.com`.

## Boot modes

- **USB / ISO:** hybrid UEFI ISO (systemd-boot → Unified Kernel Image), works with Rufus / Ventoy / `dd`
- **NetBoot:** iPXE binary + `ipxe/boot.ipxe` — chainloads kernel + initramfs over HTTP, fully compatible with netboot.xyz style servers / PXE
- **Installed helper:** optional tiny ESP entry so BC-250-X appears in your normal boot menu without the USB

## The non-negotiable safety rules

Read `docs/SAFETY.md` before you flash anything, anywhere. Short version:

1. BC-250 has **two** SPI chips. BIOS = 16 MB `W25Q128JVSQ` / `MX25L12835F` / `MX25L12873F`.
   SuperIO = 512 KB `MX25L4005A` — **BC-250-X will refuse to touch it.**
2. A flash image must be **exactly 16,777,216 bytes**, hash-verified, and ROM-ID checked.
3. No verified backup = no flash. Backup is read twice; the two reads must hash identically.
4. Proven flash path on this board is the **UEFI-shell AfuEfix64** flow the community uses
   for P3.00 — BC-250-X automates that flow instead of gambling on an unproven internal write.
   `flashrom` is included for probe / backup / external-programmer recovery (J4004 + CH347).
5. **CMOS clear after flash** is a guided, mandatory step in the wizard — skipping it is the
   #1 cause of “settings won’t save” on BC-250.

## Hardware it knows (verified, not guessed)

- APU: AMD Cyan Skillfish, `gfx1013`, PCI ID `0x13FE`
- CPU: Zen 2 — **6c/12t stock**, 8c/16t when enabled in the modded BIOS
- GPU: RDNA — **24 CU stock**, up to 40 CU via the community driver-level unlock
  (not every board is stable at 40 — diagnostics tell you, BC-250-X does not force it)
- Memory: **16 GB GDDR6 unified**, 512 MB dynamic VRAM carve is the recommended setting
- Storage: M.2 NVMe, PCIe 2.0 x2 (~1 GB/s ceiling — expensive Gen4/5 drives gain nothing here)
- I/O: DisplayPort, USB 2.0/3.0, Gigabit Ethernet, 8-pin PCIe power, ~220 W board nameplate
- Required BIOS settings it checks: modded **P3.00 Chipset Menu**, **IOMMU = Disabled**, VRAM = 512 MB dynamic
- Kernel guardrail: **avoid 6.15.0–6.15.6 and 6.17.8–6.17.10** (known GPU-init failures on BC-250)

Sources for all of the above are cited in `docs/SPEC.md`.

## Build it

```bash
# Prereqs: docker (easiest) or a Debian/Ubuntu host with the packages in scripts/prereqs.sh
./scripts/build-iso.sh          # Buildroot external tree -> output/bc250x-*.iso
./scripts/build-ipxe.sh         # -> output/bc250x-ipxe.efi  (netboot)
# Prototype UI (what's in ui-prototype/) is the exact screen/state spec for the native UI.
```

Architecture, component choices, and what is real today vs. staged are in
`docs/ARCHITECTURE.md` and `docs/ROADMAP.md` — honestly labelled, nothing oversold.

## Repo layout

```
docs/            SPEC, ARCHITECTURE, SAFETY, COMPONENTS, ROADMAP
catalog/         bios.json / os.json / tools.json  (the live signed lists)
config/          bc250x.conf.example (endpoints, mirrors, keys)
kernel/          BC-250 kernel config fragments (known-good versions only)
buildroot-external/  the tiny live system that becomes the ISO
efi/flash/       Flash.nsh automation for the proven AfuEfix64 path
ipxe/            boot.ipxe for NetBoot
scripts/         build-iso.sh, build-ipxe.sh, bc250x CLI, catalog signer
ui-prototype/    clickable prototype — open index.html, this is the product spec you can touch
```

## Nirvana OS

Listed in the OS catalog from day one, marked **Coming Soon**. When the first
Nirvana OS image (built for AI + gaming on BC-250, with the Fanalogy app
marketplace, proprietary apps and agent system preinstalled) is published to
the catalog with a hash, BC-250-X will offer it for download/install with
**no ISO update needed** — that's exactly what the live catalog is for.

---
*BC-250-X is a Fanalogy project. It builds entirely on open-source components —
see `docs/COMPONENTS.md` for the full list and licenses.*
