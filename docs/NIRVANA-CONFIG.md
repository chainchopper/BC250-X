# nirvana-config — the raspi-config for BC-250 (design, Oct 23 2026)

**Terrell's idea:** when a user installs a Nirvana-branded OS through
BC-250-X, they should get a special menu — the way Raspberry Pi's
`raspi-config` gives Pi owners one obvious place for every board option.
This is that menu, for the BC-250.

## Where it lives

- **Ships inside Nirvana OS** — offered on first boot ("Finish setting up
  your board?") and runnable any time as `nirvana-config`.
- **Offered by BC-250-X after any OS install** (Bazzite included): the
  installer drops a `nirvana-config` entry + a desktop shortcut, so the
  board-options menu follows the board, not just our OS.
- Terminal UI (works over SSH, in a TTY, in Game Mode desktop) with the same
  menu map later mirrored in the Nirvana OS settings GUI.
- **It opens the frontend app** (Terrell, Oct 23): nirvana-config is the
  terminal face of the BC-250-X options backend; on an installed OS its
  job is also to launch the **BC-250-X frontend app** (the GUI) — so users
  get every option from their desktop, *without booting the ISO*. One
  backend (`bc250x` + tool drivers), two faces: TUI here, GUI in the app.
  Only firmware flashing still reboots into Flash Mode, by design. The
  full package definition is `docs/COMPLETE-PACKAGE.md`.

## Rules it inherits (from the tooling survey, `docs/TOOLING-SURVEY.md`)

1. Every hardware change is **range-checked and confirmed** before applying.
2. **Live state and boot state are always shown separately** — nothing
   pretends a runtime tweak is permanent, or vice versa.
3. Dangerous things say so in plain language, with the recovery path named
   *before* the apply button.
4. Every section can answer "what's my current state?" without changing
   anything (status first, controls second).

## The menu

```
Nirvana Config — AMD BC-250 (gfx1013)            live ●  boot ●
 1  System status          temps, cores, CUs, BIOS, governor — one screen
 2  Compute Units (GPU)    live WGP routing (UMR), boot map, health test
 3  CPU cores              SMU unlock 6c/12t -> 8c/16t (reversible) · BIOS route
 4  Governor & clocks      Cyan / Oberon, safe-points, 1500 MHz cap preset
 5  CPU tuning             SMU boost ceiling (advanced, warned, tested)
 6  Fans & cooling         PWM, curves, profiles, hand-off to CoolerControl
 7  Memory                 VRAM carve note, ZRAM/ZSWAP, GTT size
 8  BIOS & firmware        backup · flash (catalog) · Flash & Pray · boot logo
 9  Stability tests        CU health test, compute verify, stress, memtest
10  Updates                catalog refresh, nirvana-config + tool updates
11  About this board       silicon report: harvest map, what your board held
```

### Section notes (method + posture)

- **2 · Compute Units.** Live routing via UMR (WinnieLV model): factory /
  full-40 / custom WGP table, applied live, optionally saved to a boot
  service. Boot-map alternative: kernel patch + `amdgpu.disable_cu` masking
  (duggasco model). The flow nudges: *apply full → run health test (9) →
  mask failures → save*. Markers: `D+` driver+routed, `S+` routed-only,
  `D!` driver-on-unrouted — copied semantics, our words.
- **3 · CPU cores.** Default offer is the **SMU runtime unlock**
  (reversible, per-boot service) — the friendly route the survey found.
  The permanent route is labeled honestly: "via BIOS (Flash & Pray)".
- **4 · Governor & clocks.** Governor select (Cyan / Oberon), safe-point
  presets (Stock-safe 1500 MHz/900 mV; the akandr-style AI profile; Custom
  advanced). Warns when another tool holds the SMU (governor vs tuner
  conflict is a documented footgun).
- **5 · CPU tuning.** SMU boost ceiling in the bc250_smu_oc pattern:
  detect/test first (with a stress run), apply second, persist third.
  Hard temperature guardrails; cooling note shown (stock fan throttles
  ~3.9 GHz — documented community result).
- **7 · Memory.** VRAM carve is a BIOS setting — the menu *reports* it and
  deep-links to section 8 rather than pretending to change it live. ZRAM/
  ZSWAP toggles + GTT (`ttm.pages_limit`) for the AI-profile users.
- **8 · BIOS & firmware.** A front door onto the existing `bc250x` stack —
  same gates, same catalog, no second flash path. Boot-logo choice rides
  the Flash & Pray variant system (`docs/FLASH-AND-PRAY.md`).
- **9 · Stability tests.** Per-WGP isolation health test (multi-reboot,
  clearly explained before starting), quick compute verify, CPU/GPU stress,
  memtest handoff. Results feed section 2's mask and section 11's report.
- **11 · About this board.** The keepsake screen: your board's harvest map
  with health overlay, what unlocked cleanly, what's masked, BIOS + logo,
  governor — exportable as a text report. Boards are individuals; the menu
  treats yours like one.

## Implementation

Skeleton: `tools/nirvana-config` (bash, zero deps beyond the tools it
drives). Real today: menu loop, system status (via `bc250x status` when
present), section routing, confirm/range-check helpers, live-vs-boot state
display where detectable. Integration points for `umr`, SMU tools and the
governor are called only when present, and every not-yet-wired action says
so instead of faking it. Nirvana OS ships it in `/usr/bin`; BC-250-X's
installer offers it as a post-install step for any catalog OS.
