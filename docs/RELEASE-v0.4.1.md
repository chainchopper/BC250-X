# Release setup (for the maintainer — delete this block when drafting)

- **Tag:** `v0.4.1`
- **Release title:** `BC-250-X v0.4.1 — the complete package, nothing bring-your-own`
- **Assets to attach:** `bc250x-prod-20261028.iso` + `.sha256`, and the
  netboot files from `bc250x-netboot-20261028.zip`
- **Everything below the line is the release notes body — copy from there.**

---

# BC-250-X v0.4.1 — the complete package, nothing bring-your-own

**By Fanalogy.** v0.4.1 fixes the two things v0.4.0 got wrong, by direct
product direction: the flash feature no longer needs a file we don't ship,
and Flash & Pray no longer refuses to run.

## Downloads

| File | Size | SHA-256 |
|---|---|---|
| `bc250x-prod-20261028.iso` | 142 MB | `abdee8d4c25ad675ac5a8e935d15788dff61713e1ac2de4ac0599efdc93bebe6` |
| Netboot pair (`vmlinuz` + `rootfs.cpio.gz`) | 61 MB | see `SHA256SUMS` in the netboot zip |

Verify before booting: `sha256sum -c bc250x-prod-20261028.iso.sha256`

## What changed in v0.4.1

- **Our own flasher.** The writer is now **flashrom** (GPL-2.0), bundled in
  the image: probe → verified backup → write → **read-back hash compare**.
  v0.4.0's flow depended on AMI's AfuEfix64.efi, which we did not ship —
  the headline feature needed a bring-your-own binary. That dependency is
  gone; everything the ISO needs is in the ISO.
- **Flash & Pray just works.** `bc250x pray` = verified backup → the
  catalog's recommended P3.00 Chipset BIOS (hash `48fbe5d3…`, verified
  against the catalog) → the write → Fanalogy safe presets (governor
  1500 MHz @ 900 mV cap, CMOS-clear + IOMMU-off + VRAM checklist). It runs
  the *same* gates as the manual flash flow — fewer steps, not fewer
  checks. It no longer waits on a future custom preset image; that's now
  just a planned variant.
- **Flash Mode boot entry** for GUI-staged flashes, plus the live-system
  guard: writes only ever run inside the BC-250-X live environment.
- Same v0.4 base: custom kernel 6.12.0, both real ROM payloads,
  `nirvana-config`, live catalogs, netboot pair.

## Verified

✅ Automated QEMU gate on the final ISO, all green: custom-kernel boot →
menu → `bc250x status` → `bc250x verify` on the bundled P3.00 (catalog
hash, byte-identical) → **flashrom v1.5.1 present and probing** →
**`bc250x pray` in-VM sails past every guard and stops only at "no flash
chip found"** (QEMU has none), attempting no write → Flash Mode entry
boots and no-ops cleanly with nothing staged.

## Honest limits

- ⚠️ **The flashrom write path gets its real-silicon proof on the bench**
  (`docs/BENCH-TEST.md` §7) — flashrom *reads* are proven here (the backup
  path); AfuEfix64 is the writer with the longer field history on this
  board, and the release notes say so rather than pretending otherwise.
  Backup-first, read-back verify, and the J4004/CH347 recovery path are
  all in place for that test.
- GUI-staged Flash Mode: the boot entry works; mounting the ESP inside
  the initramfs to pick up staged images is the follow-up. `bc250x pray` /
  `bc250x flash` from the booted ISO are the primary flash paths.
- The native graphical UI is still the console frontend + prototype;
  the GUI app face is post-v0.4.
