@echo -off
rem ============================================================================
rem  BC-250-X UEFI Shell Launcher - by Fanalogy (v0.4.1)
rem
rem  Since v0.4.1, BC-250-X flashes with its own writer (flashrom) inside the
rem  live image - there is no AfuEfix64 step and nothing to flash from the
rem  UEFI shell. This script's only job: boot the BC-250-X live image from
rem  this stick. Backup, restore, flash and Flash & Pray all run there
rem  (bc250x backup / bc250x flash / bc250x pray), with the full gate set.
rem
rem  Usage from a UEFI shell on the BC-250-X stick:  menu  |  menu 0r  |  menu 0s
rem ============================================================================
mode 240 56
cls

if "%1" == "0r" then
  reset -c
endif
if "%1" == "0s" then
  reset -s
endif
if "%1" == "bios" then
  echo "Run 'exit' to leave the shell, then choose Setup in the boot menu."
  goto end_menu
endif

echo "============================================================================"
echo "                        BC-250-X Launcher - by Fanalogy"
echo "============================================================================"
echo "  Booting the BC-250-X live image from this stick..."
echo "  In the live system:  bc250x pray   = backup + recommended flash + presets"
echo "                       bc250x backup = verified BIOS backup"
echo "                       bc250x flash <image.rom> = manual flash, same gates"
echo "----------------------------------------------------------------------------"

set -v BootPath ""
for %d in 0 1 2 3 4 5
  if exist fs%d:\EFI\BOOT\BOOTX64.EFI then
    set BootPath fs%d:\EFI\BOOT\BOOTX64.EFI
    goto boot_it
  endif
endfor
echo " ERROR: EFI\BOOT\BOOTX64.EFI not found on fs0:-fs5: - is this the BC-250-X stick?"
goto end_menu

:boot_it
%BootPath%

:end_menu
