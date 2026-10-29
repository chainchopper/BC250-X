# BC-250-X — BIOS Safety Model

Flashing firmware can brick a board. BC-250-X's whole design is making the
safe path the *easy* path and the dangerous path impossible to take by accident.

## The two-chip trap (the most important fact about this board)

BC-250 carries **two** SPI flash chips:

| Chip | Size | Role | Rule |
|---|---|---|---|
| W25Q128JVSQ / MX25L12835F / MX25L12873F | **16 MB** | System BIOS | Only chip BC-250-X will ever read/write |
| MX25L4005A | 512 KB | SuperIO | **Never touch. Programming it bricks the SuperIO controller.** |

Enforcement: chip-ID whitelist + size check in *both* the UI backend and the
`bc250x` CLI, independently. A probe result outside the whitelist disables
all write UI (not just a warning — the buttons are gone).

## Gates before any write

1. Image is exactly **16,777,216 bytes**.
2. Image SHA-256 matches the signed catalog (remote) or a user-confirmed hash (local).
3. Image ROM ID is in the BC-250 family.
4. A backup exists that was **read twice with matching hashes** (this session, or a sidecar-verified file on media).
5. User typed confirmation (`FLASH`), AC-power warning acknowledged.
6. Destination chip probe (read-only) returned a whitelisted 16 MB ID *in Flash Mode immediately before writing*.

## Method honesty

- **BC-250-X's writer is flashrom** (GPL-2.0, shipped in the image), running
  in the BC-250-X live environment — never from an installed OS. v0.4.0
  depended on the community's UEFI-shell **AfuEfix64** flow and did not ship
  that binary (redistribution terms); v0.4.1 removed the dependency entirely
  rather than ship a flash feature that needs a bring-your-own file.
- Stated plainly: AfuEfix64 is the writer with the longest field history on
  this board; flashrom *reads* are proven in BC-250-X (the backup path),
  and the flashrom **write** path is validated by the v0.4.1 bench flash
  test (`docs/BENCH-TEST.md` §7) before promotion claims it. Every write is
  followed by a **read-back hash comparison** — a flash is not reported
  done until the chip provably matches the image.
- flashrom is also the **external programmer recovery** tool via the board's
  J4004 header with a **CH347 (native 3.3 V)** — CH341A units that output
  5 V can damage the chip, and the recovery screen says so.

## During & after

- Flash can appear hung; the UI/Flash Mode says **wait 15 minutes, never power off**.
  Power loss mid-flash = hardware-programmer recovery (documented, § J4004).
- **CMOS clear after flash is mandatory** (battery out, 60 s). Without it,
  settings may silently not persist — the post-flash wizard does not complete until
  the user confirms it and first-boot settings (IOMMU off, VRAM 512 MB dynamic) verify.

## Flash & Pray (explicit opt-in — the exception that keeps the rules)

Flash & Pray (`docs/FLASH-AND-PRAY.md`) is the one deliberately fast path:
backup + settings snapshot → verify the **catalog's recommended BIOS**
(P3.00 Chipset) → type `PRAY` → write it with our own flasher → apply the
Fanalogy safe presets. It removes *friction*, never *checks*: the verified
backup, exact-size, hash-match, chip-whitelist and read-back gates above
all still run, and it is always an explicitly chosen action. It is exactly
as safe as the manual flash flow in the app — same writer, same gates,
fewer steps. The GPU CU unlock is not part of it — that stays an OS-level,
per-board decision with automatic fallback, exactly as the "never force"
list below requires.

## What BC-250-X will never do

- Flash from an unverified / hash-mismatched / wrong-size image.
- Flash the SuperIO chip, ever, under any flag.
- Force 40-CU / 8-core unlocks (per-board silicon lottery; it reports, you decide).
- Hide an experimental BIOS (e.g. P5.00_clv) behind the “Recommended” label.
