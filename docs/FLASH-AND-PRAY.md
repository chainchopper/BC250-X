# BC-250-X — Flash & Pray (Fanalogy Preset Mode) + UEFI Firmware Menu

**Status: designed + scaffolded (Phase 2).** The flow, gates, CLI command and
UEFI menu script exist. The one thing that does *not* exist yet is the preset
firmware image itself — until a real Fanalogy preset image is built and its
SHA-256 is filled into the signed catalog, `bc250x pray` refuses at
preflight. That is deliberate: no fake hashes, no placeholder flashes.

## Credit / what we borrowed

Terrell pointed at the community project
[Forbidden-Darkness/AMD-BC-250-UEFI-v2.2-Firmware-Menu-Script](https://github.com/Forbidden-Darkness/AMD-BC-250-UEFI-v2.2-Firmware-Menu-Script)
(GPL-3.0, same license as BC-250-X) and said: borrow what we need, make our
own. Reviewed at commit `32738db` (Oct 23 2026). What it proved and what we
took:

| Theirs (proven in the field) | Ours |
|---|---|
| UEFI-shell `menu.nsh`: pick a logo → flash a pre-built firmware variant (MeiMeiDXE v3 base: persistent 8-core unlock, ACPI fixes/toggles) | Same *shape*, our own script (`efi/menu/bc250x-menu.nsh`) — but catalog-driven: BC-250-X stages exactly **one verified image** as `BC250X.ROM`; the menu never offers unverified images |
| AfuEfix64 flash flags `/P /N /B /K /RLC:E` | Adopted verbatim into our Flash Mode template (`efi/flash/Flash.nsh.template`) — field-proven beats theoretical |
| Backup at `Firmware_Backup\bc250-backup.rom`, one-key restore (`fr`) | Same path convention in our menu (`0f` export / `fr` restore), so muscle memory and recovery guides transfer |
| Logo = a separate full firmware image per logo | Same for shipped variants (Nirvana, no-logo, Fanalogy). Custom user logos are a build-side patch step (below), not a runtime trick |
| Linux helper: `efibootmgr --bootnext` one-time boot into the USB menu, `systemctl reboot --firmware-setup` | Already BC-250-X's model (Flash Mode staging); their helper confirms the pattern |
| 17 hardcoded variants on the stick | **Not** copied. One catalog-signed preset, hash-verified before staging, is the BC-250-X way |

## Flash & Pray — the flow

One action in the GUI (BIOS screen → **Flash & Pray**) or the CLI
(`bc250x pray`). Named honestly: it's the fast path, and praying is part of
the deal — but it prays *with a verified backup in hand*.

1. **Preflight.** The Fanalogy preset entry
   (`fanalogy-p300-nirvana-preset` in `catalog/bios.json`) must be published:
   real SHA-256 in the signed catalog, image obtainable. Pending hash →
   stop here, touch nothing.
2. **Backup first — always.** Current BIOS is read **twice** with matching
   SHA-256 (the existing `bc250x backup` discipline), plus a settings
   snapshot (`bc250x status` output, `efibootmgr -v`, DMI info) saved beside
   it on USB/NVMe. No verified backup → no flash. This step cannot be
   skipped, including in Pray mode.
3. **Verify the preset.** Image is exactly 16,777,216 bytes; SHA-256 matches
   the signed catalog; chip probe returns a whitelisted 16 MB ID
   (W25Q128JVSQ / MX25L12835F / MX25L12873F) and never the SuperIO
   MX25L4005A — same gates as every BC-250-X flash (`docs/SAFETY.md`).
4. **The talk.** A plain-language screen: what changes (below), what can go
   wrong, recovery path (restore backup from the UEFI menu, `fr`; worst case
   CH347 via J4004). Confirmation is typing `PRAY`.
5. **Stage + flash.** Image staged to the ESP; reboot into Flash Mode; the
   UEFI menu (`bc250x-menu.nsh`) runs AfuEfix64 with the proven flags.
6. **After.** Mandatory CMOS clear (battery out, 60 s), then the post-flash
   wizard verifies first-boot presets: IOMMU **Disabled**, VRAM **512 MB
   Dynamic**, cores read **8 / 16**.

### What the preset changes — and what it does not

- ✅ **All cores:** 8 cores / 16 threads unlocked persistently (that's in the
  preset firmware, a P3.00 Chipset-family build with the chipset menu and
  Fanalogy defaults baked in).
- ✅ **Nirvana boot logo** (default variant) — the board boots with our logo,
  not a mining-rig splash.
- ✅ **Presets baked in:** IOMMU Disabled, dynamic VRAM default, ACPI fixes
  of the P3.00 modded family.
- ⚠️ **40 CU is NOT a firmware feature.** The GPU unlock (24 → up to 40 CU)
  is a driver/OS-level change with per-board stability — some boards only
  hold 32/36. Flash & Pray does **not** pretend otherwise: after a verified
  first boot, BC-250-X offers the CU unlock in the OS (oberon /
  cyan-skillfish governor profile) with a stability warning and automatic
  fallback. Silicon lottery is silicon lottery; the firmware flash neither
  causes it nor cures it.

### Safety-doc amendment

`docs/SAFETY.md` says BC-250-X will never *force* unlocks. Flash & Pray does
not break that: it is never the default, never silent, never one accidental
click — it is an explicitly chosen mode that still enforces every brick-proof
gate (verified backup, size, hash, chip whitelist) before anything writes.
What it removes is *friction*, not *checks*.

## The Fanalogy preset image — build TODO (the real remaining work)

- [ ] Produce our preset build from the community modded P3.00 base
      (TuxThePenguin0 bc250-bios family): chipset menu, core config unlocked,
      Fanalogy defaults (IOMMU off, VRAM 512 MB dynamic).
- [ ] Patch the boot-logo module with the **Nirvana logo** (build-side, e.g.
      UEFITool logo-module replacement on a copy of the base image; verify
      the image is still exactly 16,777,216 bytes and parses clean).
- [ ] Variants: `nirvana` (default), `none` (splash disabled), `fanalogy`.
- [ ] Hash the real images, fill `sha256` in `catalog/bios.json`, minisign
      the catalog. Only then does `bc250x pray` un-refuse.
- [ ] Bench-verify on a sacrificial board before the entry leaves `planned`.

## Custom user logos (staged sub-feature)

Same build-side mechanism, user-supplied artwork: user picks an image in the
GUI → BC-250-X validates format/size against the logo module's constraints →
builds a personal variant from the published preset → shows its hash and
pins it as a *local* catalog entry (user's own trust, clearly labeled
"local build — not Fanalogy-signed") → same gates, same Flash Mode. The
signing line stays bright: Fanalogy signs Fanalogy images only.
