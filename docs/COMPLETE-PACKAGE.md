# BC-250-X — The Complete Package (v0.4 definition, Oct 23 2026)

Terrell's call: we have everything we need — finish it, package it, test it,
promote it. This doc is the single definition of what "the package" is, so
the build, the release and the promotion all describe the same thing.

## The package (v0.4)

**One ISO, everything bundled, netbootable, with an installed-OS life after
the install.**

1. **Production ISO** — Buildroot, custom kernel 6.12 LTS (guardrail range,
   gfx1013/oberon baked in). Boots UEFI to the BC-250-X frontend.
2. **The flashing feature, front and center** — the thing users want before
   installing anything: verified backup (double-read), catalog flashing
   (real SHA-256s now live for P3.00 Chipset + stock P3.00), Flash & Pray
   staging, our UEFI firmware menu, recovery path. AfuEfix64 = bring-your-own
   or staged (redistribution decision still open — the ISO ships the *flow*,
   gates and menus regardless).
3. **The full tool bundle in the ISO** — `bc250x` CLI, `nirvana-config`,
   diagnostics/stress set, BIOS payloads (P3.00 Chipset + stock recovery),
   live signed catalogs. A user with only our USB stick has the whole kit.
4. **NetBoot** — the build emits `vmlinuz` + initramfs + `boot.ipxe` beside
   the ISO: iPXE kernel/initrd boot over HTTP (plus ISO sanboot). Boot it
   from the network, no stick required.
5. **nirvana-config + the BC-250-X App (installed-OS life)** — after any
   install, the board keeps its options *without booting the ISO*:
   `nirvana-config` (terminal) is the launcher/face of the same options
   backend that powers the **BC-250-X frontend app** on the installed OS —
   one backend (`bc250x` + the surveyed tool drivers: UMR CU routing, SMU
   core unlock/tuning, governor, fans), two faces (TUI + GUI). Config
   opens the app; the app covers the everyday options; only firmware
   flashing still reboots into Flash Mode, by design.
6. **Windows is in scope** — the board is no longer Linux-only: D-Ogi's
   **Nagi** driver (`github.com/D-Ogi/amdgpu-wddm`, experimental, test-signed)
   runs Windows 11 + D3D12/Vulkan gaming on gfx1013, with its own control
   app. BC-250-X's Windows track:
   - OS catalog gains a **Windows 11 + Nagi** guided entry (Experimental):
     install Windows → run the Nagi installer (it board-checks, fetches GPU
     firmware, enables test mode; Secure Boot off) → Nagi Control App for
     clocks/temps/fan.
   - The UEFI/flash side is already OS-agnostic — a Windows user's BIOS
     backup/flash path is the same BC-250-X stick/netboot.
   - A native Windows face for the BC-250-X App is a post-v0.4 build;
     v0.4 ships the guidance + catalog entry, and **links** Nagi rather
     than redistributing it (its license is unasserted — review first).

## Test gates before anyone promotes anything

- [ ] Production ISO passes the automated QEMU gate on the custom kernel
- [ ] `bc250x verify` on the bundled P3.00 payload from the booted ISO
- [ ] Bench boot on a real BC-250 (`docs/BENCH-TEST.md`) — menu + status
- [ ] Flash-flow bench sequence on the test board: backup → export →
      restore dry path, then the real flash test Terrell runs himself
- [ ] NetBoot smoke test (iPXE fetch of vmlinuz + initramfs)

Promotion copy (`docs/PROMO-KIT.md`) locks only after the gates it claims
have actually passed. If the bench flash hasn't happened yet, the posts say
"flashing flow — bench verification in progress", because that's true.

## Promotion targets (drafts in PROMO-KIT.md — nothing posts without Terrell)

- GitHub Release v0.4 (the ISO + netboot files + hashes)
- The BC-250 community Discord (amd-bc250-docs community, 3,500+ members)
- Reddit BC-250 / ASRock / homelab communities
- amd-bc250-docs (elektricM) — a docs PR/listing offer, not an ad
- X / Fanalogy channels
- The YouTube creators covering BC-250 (the Nagi/Windows video's channel
  among them) — a test-key style outreach: "your viewers asked for one tool"
