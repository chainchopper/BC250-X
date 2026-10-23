# Release setup (for the maintainer — delete this block when drafting)

- **Tag:** `v0.4.0`
- **Release title:** `BC-250-X v0.4.0 — the complete BC-250 toolkit`
- **Assets to attach:** `bc250x-prod-20261023.iso` + `.sha256`, and the
  netboot files (`vmlinuz`, `rootfs.cpio.gz`, `SHA256SUMS`, `boot.ipxe`)
- **Everything below the line is the release notes body — copy from there.**

---

# BC-250-X v0.4.0 — the complete BC-250 toolkit

**By Fanalogy.** One ISO (or a netboot) that carries the whole BC-250
toolkit: a custom-kernel live front-end, the BIOS backup/flash flow with
real safety gates, the curated OS catalog, and `nirvana-config` — the
board's raspi-config. Built only for the AMD BC-250.

## Downloads

| File | Size | SHA-256 |
|---|---|---|
| `bc250x-prod-20261023.iso` | 140 MB | `3d19b435834778b6db24f3782a511530e23ff5f8344329cdbf4b28ff69c21be7` |
| Netboot pair (`vmlinuz` + `rootfs.cpio.gz`) | 61 MB | see `SHA256SUMS` in the netboot zip |

Verify before booting: `sha256sum -c bc250x-prod-20261023.iso.sha256`

## What's in v0.4

- **Custom kernel 6.12.0** (guardrail range) with amdgpu built in +
  Cyan Skillfish firmware — no more distro-kernel shortcut
- **The flashing feature**: `bc250x backup` (double-read, hash-matched),
  `bc250x flash` staging, our UEFI firmware menu (`bc250x-menu.nsh`),
  and bundled payloads — the real community **P3.00 Chipset Menu** BIOS
  (`48fbe5d3…`) and **stock P3.00** recovery (`07595ca3…`), both
  hash-verified against the signed catalog format
- **Flash & Pray** scaffolding (`bc250x pray`) — refuses until the
  Fanalogy Nirvana preset image is published (it isn't yet; no fake hashes)
- **`nirvana-config`** in the image: status, cores, CUs, governor, BIOS,
  tests — the board menu that also lives in your installed OS
- **NetBoot**: iPXE kernel+initrd files beside the ISO (`boot.ipxe`)
- Live catalogs (Bazzite default; Nirvana OS coming soon; Windows 11 +
  Nagi driver path documented)

## Verified

✅ Automated QEMU/OVMF gate on the final ISO, all green:
`BC250X_BOOT_OK kernel=6.12.0` → menu → `bc250x status` → shell
`bc250x verify` on the bundled P3.00 payload returns its catalog
SHA-256 byte-identically → clean poweroff. Test scripts ship in-repo.

## Honest limits

- ⚠️ **Real-board bench test is the next gate** (`docs/BENCH-TEST.md`).
  QEMU cannot emulate gfx1013 or a real flash chip — the first bench
  flash is a test, on a board whose owner accepts that, backup in hand.
- **AfuEfix64 is bring-your-own**: drop `AfuEfix64.efi` into `EFI\BOOT`
  on the stick (every community BC-250 kit has it). BC-250-X ships the
  flow, gates and menus; the AMI binary's redistribution terms are the
  one open legal item, so it is not bundled.
- Flashing happens via the gated UEFI-shell flow (the proven BC-250
  method) — nothing in the Linux boot path writes the BIOS directly.
- The native graphical UI is still the console frontend + prototype;
  the GUI app face is post-v0.4.

## Version history

- **v0.1** scaffold · **v0.2** catalog lineup · **v0.3** Phase 1 ISO
  (distro kernel, QEMU) · **v0.4.0** complete package (this release)

Design + survey + package definition: `docs/COMPLETE-PACKAGE.md`,
`docs/TOOLING-SURVEY.md`, `docs/FLASH-AND-PRAY.md`, `docs/NIRVANA-CONFIG.md`
