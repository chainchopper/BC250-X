# BC-250-X — Roadmap

## Phase 0 — v0.1 (this delivery) ✅
- [x] Hardware truth verified + cited spec (stock vs. unlocked, two-chip trap, kernel guardrails)
- [x] Architecture on proven open-source parts, AfuEfi honesty flagged
- [x] Signed live-catalog schemas + real seed entries (BIOS + OS)
- [x] Buildroot external-tree skeleton, kernel fragments, iPXE script, Flash.nsh template
- [x] `bc250x` CLI wrapper (status / backup / verify; flash via gated staging)
- [x] Clickable UI prototype — every screen from the request, with real values/states

## Phase 1 — First bootable ISO
- [x] First bootable ISO via the fast assembler (`scripts/build-iso-phase1.sh`): Ubuntu 24.04 kernel binary (6.8.0-147 — owner-proven family on real BC-250s) + busybox initramfs with the real `bc250x` CLI + Phase 1 menu. 69 MB, UEFI El Torito. **Oct 21 2026.**
- [x] QEMU boot test (OVMF/UEFI), automated serial drive: boot marker → menu → `bc250x status` runs → clean poweroff. `scripts/test-qemu-drive.py`, log in `build/qemu-drive.log`. **Passed clean Oct 21 2026.**
- [ ] Finish Buildroot defconfig → custom-kernel ISO (production path; the fast assembler is the Phase 1 proof, not the final kernel)
- [ ] Port prototype → native Slint UI on DRM/KMS
- [ ] Hardware probe + Dashboard live on real BC-250 (needs a board on the bench / remote hands)
- **Gate (updated):** ISO boots to BC-250-X on a real BC-250. QEMU gate passed.

## Phase 2 — BIOS flows
- [ ] Backup double-read + sidecar, verified on real chip IDs
- [ ] Flash Mode automation of AfuEfix64 flow + logging + post-flash CMOS/settings wizard
- [ ] Recovery screen (J4004 + CH347 + flashrom) tested with an external programmer
- **Gate:** backup → flash P3.00 → verify, end-to-end on a sacrificial board.

## Phase 3 — OS catalog + install
- [ ] Catalog signing keys generated, GitHub + Fanalogy mirror live
- [ ] Download/verify/write-to-USB flow; NVMe install flow for Bazzite/Fedora BC-250 images
- [ ] NetBoot (iPXE) tested against a local PXE server + netboot.xyz chainload
- **Gate:** fresh board → BC-250-X USB → install Bazzite → Boot OS, no other tools touched.

## Phase 4 — Nirvana OS
- [ ] Nirvana OS catalog entry flips `coming_soon → available` the day an image + hash is published
- [ ] First-boot handoff: BC-250-X → Nirvana OS agent/marketplace setup
- [ ] BC-250-X ESP helper entry so the tool lives in the normal boot menu

## Decisions needed from Terrell / Fanalogy
1. ~~**Catalog hosting**~~ — DECIDED Oct 20: `chainchopper/BC250-X` public repo + `downloads.fanalogy.com` mirror. OS lineup decided the same day: Bazzite default; Ubuntu 26.04 LTS + SteamOS added as Experimental-on-BC-250.
2. **Signing key:** who holds the minisign private key for catalog releases?
3. **AfuEfix64 redistribution:** ship it in the ISO or bring-your-own? (legal check, see COMPONENTS.md)
4. **Bench board:** is there a sacrificial BC-250 for Phase 2 flash testing?
5. **Nirvana OS:** base (Fedora/Bazzite-derived vs. from-scratch Buildroot/Yocto) + image ETA — BC-250-X is ready for it either way.
