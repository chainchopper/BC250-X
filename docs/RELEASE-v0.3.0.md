# Release setup (for the maintainer — delete this block when drafting)

- **Tag:** `v0.3.0`
- **Release title:** `BC-250-X v0.3.0 — Phase 1 bootable ISO`
- **Assets to attach:** `bc250x-phase1-20261021.iso` + `bc250x-phase1-20261021.iso.sha256`
- **Everything below the line is the release notes body — copy from there.**

---

# BC-250-X v0.3.0 — Phase 1 bootable ISO

**By Fanalogy.** The first bootable BC-250-X image: a UEFI front-end built only
for the AMD BC-250. Write it to a USB stick, boot it, and you get the BC-250-X
menu with live system status from the real `bc250x` tool — no OS install
required.

## Download

| File | Size | SHA-256 |
|---|---|---|
| `bc250x-phase1-20261021.iso` | 69 MB | `9f02009010d36a8326637ef4483e2ce4ed7f65744464da32d9d741da0fb7dd79` |

Verify your download before booting:

```bash
sha256sum bc250x-phase1-20261021.iso   # must match the hash above
```

## How to use it

1. Write the ISO to a USB stick (Rufus, Ventoy, or `dd` — it's a hybrid image):
   `sudo dd if=bc250x-phase1-20261021.iso of=/dev/sdX bs=4M status=progress`
2. Boot the BC-250 from USB in **UEFI mode**.
3. Pick from the menu: **System status** · **Catalog check** · **Shell** ·
   **Reboot** · **Power off**.

System status shows CPU model and core/thread count, board and BIOS info
from DMI, the running kernel, and the BC-250 kernel guardrail check.

## What's inside

- GRUB EFI standalone bootloader, hybrid El Torito ISO (UEFI)
- Ubuntu 24.04 kernel binary **6.8.0-147-generic** — the kernel family owner
  builds already run on real BC-250s
- Hand-rolled busybox initramfs carrying the Phase 1 menu, the real `bc250x`
  CLI, and the signed catalog files (`bios.json` / `os.json` / `tools.json`)
- The OS catalog defaults to **Bazzite**; Nirvana OS is listed as Coming Soon

## Verified

✅ **Boot-tested in QEMU/OVMF** by an automated serial-console drive test:
UEFI → GRUB → kernel → BC-250-X menu → `bc250x status` runs → clean power
off, zero errors. The test script ships in the repo
(`scripts/test-qemu-drive.py`) so anyone can reproduce it.

## Honest limits — read this

- ⚠️ **Not yet booted on a real BC-250.** QEMU is the Phase 1 gate; the
  real-board bench test is the next step (Phase 1.1). Reports welcome.
- This build uses a distro kernel binary. The production custom kernel
  (6.12–6.14 LTS + gfx1013/oberon governor, Buildroot build) comes later.
- The Phase 1 menu is a console front-end. The native graphical UI (port of
  the clickable prototype in this repo) is a later phase.
- **Nothing in this ISO flashes anything.** BIOS backup/flash flows stay
  gated exactly as specified in `docs/SAFETY.md` and arrive in Phase 2.
  Never flash the 512KB SuperIO chip — BIOS images are exactly
  16,777,216 bytes; read `docs/SAFETY.md` before flashing anything, anywhere.

## Version history

- **v0.1** — spec, signed catalogs, `bc250x` CLI, clickable UI prototype
- **v0.2** — OS lineup finalized (Bazzite default; Ubuntu 26.04 + SteamOS)
- **v0.3.0** — Phase 1 bootable ISO (this release)

Full technical notes: `docs/PHASE1.md` · Roadmap: `docs/ROADMAP.md`
