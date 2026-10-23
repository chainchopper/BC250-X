# BC-250-X — Open-Source Components

Everything BC-250-X needs already exists as open source. This is the bill of materials.

| Component | Role | License |
|---|---|---|
| Linux kernel (LTS, known-good range) | Custom kernel, gfx1013 + oberon patches | GPL-2.0 |
| Buildroot | Live-system / ISO build | GPL-2.0+ |
| systemd-boot | UEFI boot manager | LGPL-2.1+ |
| iPXE | NetBoot | GPL-2.0+ |
| Slint *or* LVGL | Native framebuffer UI | GPL / royalty-free (Slint) / MIT (LVGL) — pick at Phase 1 |
| flashrom | Chip probe, backup, external-programmer recovery | GPL-2.0 |
| AfuEfix64.efi / amdvbflash.efi | Proven BC-250 UEFI-shell flash executables (AMI / AMD tools, redistributed by the community BIOS project) | Proprietary freeware tools — **flagged:** confirm redistribution terms before shipping in a commercial ISO; fallback is “bring your own” drop-in folder, which the Flash Mode already supports |
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

**Honesty note:** AfuEfix64 is the one non-open-source piece, because it is the
*proven* tool for this board. BC-250-X isolates it to Flash Mode, supports a
bring-your-own binary, and never hides its presence.
