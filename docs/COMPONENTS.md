# BC-250-X — Open-Source Components

Everything BC-250-X needs already exists as open source. This is the bill of materials.

| Component | Role | License |
|---|---|---|
| Linux kernel (LTS, known-good range) | Custom kernel, gfx1013 + oberon patches | GPL-2.0 |
| Buildroot | Live-system / ISO build | GPL-2.0+ |
| systemd-boot | UEFI boot manager | LGPL-2.1+ |
| iPXE | NetBoot | GPL-2.0+ |
| Slint *or* LVGL | Native framebuffer UI | GPL / royalty-free (Slint) / MIT (LVGL) — pick at Phase 1 |
| flashrom | **The flasher**: chip probe, verified backup, gated writes + read-back verify in the live image; external-programmer recovery | GPL-2.0 |
| AfuEfix64.efi | The community's legacy UEFI-shell flasher for this board (AMI tool). **Not shipped and not used since v0.4.1** — BC-250-X writes with flashrom so the ISO is complete out of the box; the old template stays in-repo as reference | Proprietary — not redistributed |
| memtest86+ | RAM diagnostics (EFI) | GPL-2.0 |
| stress-ng | CPU stress | GPL-2.0 |
| smartmontools, nvme-cli, fio | Storage diagnostics | GPL-2.0 / Apache-2.0 |
| lm-sensors | Sensor readout fallback | LGPL/GPL |
| efibootmgr, dmidecode | EFI entries, DMI/BIOS info | GPL-2.0 / GPL |
| iwd / wpa_supplicant, linux-firmware | USB Wi-Fi | LGPL / BSD / redistributable firmware |
| minisign | Catalog signing/verification | ISC |
| xorriso | Hybrid ISO creation | GPL-3.0 |
| Community BC-250 work this builds on | Modded P3.00 Chipset-Menu BIOS (TuxThePenguin0/bc250-bios), amd-bc250-docs (elektricM), oberon governor + CU-unlock research (duggasco et al.) | Per upstream — credit in-app on the About screen |
| Forbidden-Darkness/AMD-BC-250-UEFI-v2.2-Firmware-Menu-Script | Design/mechanics reference for our UEFI firmware menu + Flash & Pray: field-proven AfuEfix64 flag set (`/P /N /B /K /RLC:E`), backup-path convention (`Firmware_Backup\bc250-backup.rom`), logo-variant model. Our `efi/menu/bc250x-menu.nsh` is original code, catalog-driven (one staged verified image) rather than a copy of their hardcoded-variant script. | GPL-3.0 (same license as BC-250-X) |
| movacx/bc250-control-center | The installed-OS control-center benchmark (dashboard, governor, SMU tuning, CU live-vs-boot state, fans, memory, verified BIOS media, FSR4, Decky). UX rules adopted project-wide (range-check + confirm; live vs boot state). Nirvana OS integration/marketplace candidate — see `docs/TOOLING-SURVEY.md` | MIT |
| WinnieLV/bc250-cu-live-manager · duggasco/bc250-40cu-unlock · bc250-collective/bc250_smu_oc | Design references for nirvana-config: UMR live WGP/CU routing + SMU core unlock; per-WGP health test + selective CU masking; SMU CPU OC pattern. Linked from `catalog/tools.json`; no code bundled (licenses not stated in those repos as of Oct 23 2026) | Unstated upstream — reference only |

**Honesty note (updated v0.4.1):** BC-250-X ships **no** proprietary
flasher. v0.4.0 leaned on the community's AfuEfix64 flow without shipping
the binary; that made the headline feature incomplete out of the box, so
the dependency was removed — flashrom (GPL-2.0) probes, backs up, writes
and read-back-verifies. The write path's bench validation is tracked in
`docs/BENCH-TEST.md` §7 and `docs/SAFETY.md` (Method honesty).
