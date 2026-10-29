# BC-250-X — Flash & Pray (the recommended flash + Fanalogy safe presets)

**Status: LIVE since v0.4.1 (Oct 28 2026).** Terrell's product call, verbatim
in spirit: *Flash & Pray is simply running the flash and using our default
safe presets for best performance — it is not any less safe than manual
config inside our app.* So that's what it is. The earlier design gated the
mode on a not-yet-built custom Nirvana-logo image and *refused* until it
existed; that gate is gone. The Nirvana-logo image is now just a future
variant option, never a blocker.

## What Flash & Pray does (`bc250x pray`, from the live ISO / netboot)

1. **Verified backup — always.** Current BIOS read twice, hashes must match
   (`bc250x backup` discipline), plus a settings snapshot. No verified
   backup → no write. This step cannot be skipped.
2. **Target = the catalog's recommended BIOS** — the community P3.00
   Chipset Menu build, bundled in the ISO payload and verified against the
   catalog SHA-256 (`48fbe5d3…`) before anything writes.
3. **Typed confirmation** (`PRAY`) — a human decision, not an accident.
4. **The write runs with BC-250-X's own flasher: flashrom** (GPL-2.0,
   shipped in the image). Chip probe must return a whitelisted 16 MB ID
   (W25Q128JVSQ / MX25L12835F / MX25L12873F), never the SuperIO MX25L4005A.
   After the write, the chip is **read back and hash-compared** to the
   image — the flash isn't "done" until the chip provably matches.
5. **Fanalogy safe presets applied/printed:** governor safe-points
   (1500 MHz cap @ 900 mV) where the governor config exists, and the
   post-flash checklist — mandatory CMOS clear, then verify IOMMU
   **Disabled**, VRAM **512 MB Dynamic**, 8C/16T config in the chipset menu.
6. **CU routing (24→40) is not firmware** and never pretends to be: it
   lives in `nirvana-config`, live, health-tested per-WGP, masked.

The manual path (`bc250x flash <image>`, or the GUI equivalent) runs the
*same* gates and the *same* writer — Pray just picks the recommended image
and the presets for you. Non-catalog local images are allowed on the manual
path with a hash-confirmation step; Pray only ever flashes the catalog
image.

**Flash Mode** (for GUI-staged flashes): the GUI stages one verified image
to the ESP (`bc250x-flash/BC250X.ROM`); the "BC-250-X Flash Mode" boot
entry boots the live image with `bc250x.flashmode=1` and the init runs
`bc250x flashmode`, which applies the identical flow. Writes only ever run
inside the BC-250-X live environment — never from an installed OS.

## The flasher: ours, not AMI's (v0.4.1 change)

v0.4.0 depended on **AfuEfix64.efi**, which BC-250-X did *not* ship
(redistribution terms unresolved) — so the headline flash feature needed a
bring-your-own binary. Unacceptable for a "complete package." Per Terrell's
direction ("if using afu is an issue rewrite that shit"), v0.4.1 removes
the dependency entirely:

- **Writer:** flashrom internal programmer, shipped in the ISO.
- Honest caveat, stated once: the community's field-proven writer on this
  board was AfuEfix64; flashrom *reads* are proven here (our backup path),
  and the **write path is validated by the v0.4.1 bench flash test**
  (`docs/BENCH-TEST.md` §7) before any promotion claims it. The verified
  backup + read-back compare + J4004/CH347 external recovery story is
  unchanged.
- The old UEFI-shell template (`efi/flash/Flash.nsh.template`) and the AFU
  menu are retained in-repo as **legacy reference only**; the shipped
  `efi/menu/bc250x-menu.nsh` is now a boot launcher into the live image.

## Credit / what we borrowed

Terrell pointed at
[Forbidden-Darkness/AMD-BC-250-UEFI-v2.2-Firmware-Menu-Script](https://github.com/Forbidden-Darkness/AMD-BC-250-UEFI-v2.2-Firmware-Menu-Script)
(GPL-3.0) and said: borrow what we need, make our own. What we kept: the
*idea* of a one-action preset flash with the backup kept beside it, and the
lesson that users want exactly one button for "the good BIOS, please."
What we changed: catalog-driven single verified image (not 17 hardcoded
variants), our own open-source writer (not the AMI binary), read-back
verification, and presets as checked settings rather than baked promises.

## The Fanalogy preset image — future variant (not a blocker)

A Fanalogy-built variant (P3.00-family base + Nirvana boot logo + baked
defaults) remains a nice-to-have. When it exists, it gets hashed into the
catalog and becomes a *choice* in the flash screen. Flash & Pray does not
wait for it. Custom user logos follow the same rule: build-side variant,
user's own local trust label, same gates.
