# BC-250-X — Promotion Kit (DRAFTS — nothing here is posted)

**Rules:** every draft locks only after the gate it claims has passed
(see `docs/COMPLETE-PACKAGE.md`). Terrell approves final copy before
anything goes out. Claims stay at the level the evidence supports:
QEMU-verified ≠ bench-verified ≠ flash-verified — the drafts mark which.

---

## 1. GitHub Release v0.4 (the anchor everything links to)

Title: `BC-250-X v0.4 — the complete BC-250 toolkit`
Assets: production ISO + `vmlinuz` + initramfs + `boot.ipxe` + SHA-256s.
Body: adapt `docs/RELEASE-v0.3.0.md` structure; add: custom 6.12 kernel,
flashing feature + real catalog hashes, tool bundle, nirvana-config,
netboot files, Windows/Nagi guided entry. Status line per feature.

## 2. Discord — BC-250 community (#showcase / #announcements style)

> **BC-250-X v0.4 — one stick (or netboot) for the whole board** 🛠️
> By Fanalogy. A UEFI front-end built only for the BC-250:
> • Backup + flash BIOS from a signed live catalog (real hashes, chip-whitelist gates, double-read backups) — incl. a Flash & Pray preset flow
> • Live system/BIOS dashboard, curated OS installs (Bazzite default, Nirvana OS coming soon)
> • `nirvana-config` — a raspi-config-style menu for the board: live CU routing, SMU core unlock, governor, fans
> • NetBoot files included (iPXE)
> Built on the community's work — TuxThePenguin0's BIOS, the Forbidden-Darkness menu flow, movacx + WinnieLV + duggasco tooling (all credited in-repo).
> Repo + ISO: github.com/chainchopper/BC250-X
> Honest status: [QEMU-verified / bench-verified — update at post time]. Flashing is gated, not magic: it backs up before it writes, and it will refuse a bad image.

## 3. Reddit — r/BC250 et al. (title + body)

Title: `BC-250-X: a bootable all-in-one front-end for the BC-250 (BIOS backup/flash, OS installs, nirvana-config) — open source`

Body (draft):
> I built the tool I wanted when I got my board. BC-250-X boots from USB
> or netboot into a front-end that shows live board/BIOS info, backs up
> your BIOS (read twice, hashes must match), flashes from a signed
> catalog with chip-whitelist gates, installs curated OSes (Bazzite is
> the default), and drops a raspi-config-style menu (`nirvana-config`)
> into your installed OS for CU routing / SMU core unlock / governor /
> fans. Windows folks: it also catalogs the Windows 11 + Nagi driver
> path. Everything's GPL-3 and credited — it stands on TuxThePenguin0,
> Forbidden-Darkness, movacx, WinnieLV, duggasco and the amd-bc250-docs
> community. [Verification status line.] Feedback + sacrificial-board
> reports welcome.

## 4. amd-bc250-docs — contribution, not an ad

Open a PR/issue offering a BC-250-X entry for their tooling pages:
one paragraph + link, written to their docs' tone, crediting the docs as
a source BC-250-X itself relies on.

## 5. X / short-form

> Your BC-250 deserves a front-end. BC-250-X v0.4: BIOS backup & flash
> with real safety gates, curated OS installs, a raspi-config for the
> board, netboot-ready. Open source by Fanalogy.
> github.com/chainchopper/BC250-X

## 6. Creator outreach (YouTube BC-250 channels — incl. the Nagi video's)

Short DM/email draft:
> Loved your BC-250 coverage. We just shipped BC-250-X — an open-source
> bootable front-end for the board (BIOS backup/flash with safety gates,
> OS installs, a board config menu that also lives in the installed OS).
> It even catalogs the Windows 11 + Nagi path your video covered. ISO +
> netboot files are on the release page if you want to try it on your
> bench board — happy to fix anything you find on camera.

---

**Posting checklist (Terrell):** approve copy → confirm verification status
lines are accurate *that day* → post GitHub Release first (everything
links there) → Discord → Reddit → docs PR → X → creator outreach.
