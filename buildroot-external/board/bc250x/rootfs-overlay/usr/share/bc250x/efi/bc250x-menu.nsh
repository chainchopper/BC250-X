@echo -off
rem ============================================================================
rem  BC-250-X UEFI Firmware Menu - by Fanalogy
rem  Runs in the UEFI shell from the BC-250-X USB / Flash Mode staging.
rem
rem  Design (see docs/FLASH-AND-PRAY.md): this menu NEVER browses for images.
rem  BC-250-X stages exactly one catalog-verified image as BC250X.ROM beside
rem  AfuEfix64.efi before rebooting here. The menu flashes that, backs up the
rem  current ROM, or restores the backup - nothing else.
rem  Backup path convention (Firmware_Backup\bc250-backup.rom) matches the
rem  community menu scripts, so existing recovery guides transfer.
rem ============================================================================
mode 240 56
cls

if "%1" == "" then
  goto show_menu
endif
if "%1" == "01" then
  goto FLASH_STAGED
endif
if "%1" == "0f" then
  goto BACKUP
endif
if "%1" == "fr" then
  goto RESTORE
endif
if "%1" == "bios" then
  goto EXITSETUP
endif
if "%1" == "0r" then
  goto REBOOT
endif
if "%1" == "0s" then
  goto SHUTDOWN
endif
echo "Invalid selection: %1"
echo "Press Enter to return to the menu."
pause -q
goto show_menu

:show_menu
cls
echo "============================================================================"
echo "                        BC-250-X Firmware Menu - by Fanalogy"
echo "============================================================================"
echo "  The staged image (BC250X.ROM) was verified by BC-250-X before reboot:"
echo "  exact size 16777216 - SHA-256 matches the signed catalog - chip checked."
echo "----------------------------------------------------------------------------"
echo " "
echo "   [menu 01]  Flash staged image (Fanalogy preset / chosen BIOS)"
echo " "
echo "   [menu 0f]  Export current ROM backup  -> Firmware_Backup\bc250-backup.rom"
echo "   [menu fr]  Restore ROM backup         <- Firmware_Backup\bc250-backup.rom"
echo " "
echo "   [menu bios] Exit menu   /   [menu 0r] Cold reset   /   [menu 0s] Shutdown"
echo " "
echo "============================================================================"
echo "  Syntax: menu 01   (0 = numeric zero)"
echo "============================================================================"
goto end_menu

:FLASH_STAGED
cls
echo -b " +----------------------------------------------------------------------+"
echo -b " [X]              WARNING: FLASH FIRMWARE AT YOUR OWN RISK!           [X]"
echo -b " [X]   DO NOT POWER OFF during the flash. It can look hung - wait      [X]"
echo -b " [X]   at least 15 minutes before concluding anything is wrong.       [X]"
echo -b " +----------------------------------------------------------------------+"
echo " "
echo " Target: BC250X.ROM (staged + verified by BC-250-X)"
echo " If you have NOT exported a backup (menu 0f) in this session and do not"
echo " have a verified BC250 backup on this stick - go back and do that first."
echo " "
echo " Press Enter to flash, or Ctrl-C / reset to walk away."
pause -q
set -v AfuPath ""
for %d in 0 1 2 3
  if exist fs%d:\EFI\BOOT\AfuEfix64.efi then
    if exist fs%d:\EFI\BOOT\BC250X.ROM then
      set AfuPath fs%d:\EFI\BOOT
      goto flash_run
    endif
  endif
endfor
goto drive_error
:flash_run
%AfuPath%\AfuEfix64.efi %AfuPath%\BC250X.ROM /P /N /B /K /RLC:E
echo " "
echo " Flash command finished. NOW: remove power, clear CMOS (battery out,"
echo " 60 seconds), then boot BC-250-X to finish the post-flash wizard"
echo " (IOMMU off, VRAM 512MB dynamic, cores 8/16)."
pause -q
reset -c

:BACKUP
set -v AfuPath ""
for %d in 0 1 2 3
  if exist fs%d:\EFI\BOOT\AfuEfix64.efi then
    set AfuPath fs%d:
    goto backup_run
  endif
endfor
goto drive_error
:backup_run
mkdir %AfuPath%\Firmware_Backup
%AfuPath%\EFI\BOOT\AfuEfix64.efi %AfuPath%\Firmware_Backup\bc250-backup.rom /O
echo " "
echo " Backup written to %AfuPath%\Firmware_Backup\bc250-backup.rom"
echo " Verify its size is 16777216 bytes before trusting it."
pause -q
goto show_menu

:RESTORE
cls
echo -b " +----------------------------------------------------------------------+"
echo -b " [X]   RESTORE: this flashes your BACKUP image back onto the board.   [X]"
echo -b " [X]   Same rules: do not power off, wait at least 15 minutes.        [X]"
echo -b " +----------------------------------------------------------------------+"
echo " "
echo " Press Enter to restore, or Ctrl-C / reset to walk away."
pause -q
set -v AfuPath ""
for %d in 0 1 2 3
  if exist fs%d:\EFI\BOOT\AfuEfix64.efi then
    if exist fs%d:\Firmware_Backup\bc250-backup.rom then
      set AfuPath fs%d:
      goto restore_run
    endif
  endif
endfor
goto drive_error
:restore_run
%AfuPath%\EFI\BOOT\AfuEfix64.efi %AfuPath%\Firmware_Backup\bc250-backup.rom /P /N /B /K /RLC:E
echo " "
echo " Restore finished. Remove power, clear CMOS (battery out, 60s), reboot."
pause -q
reset -c

:drive_error
cls
echo " ERROR: AfuEfix64.efi and/or the required .ROM not found on fs0:-fs3:."
echo " BC-250-X stages them under EFI\BOOT - is this the right USB stick?"
pause -q
goto show_menu

:EXITSETUP
echo " Leaving the menu. Run 'exit' to leave the shell, then pick Setup"
echo " in your board's boot menu if you need the BIOS screens."
goto end_menu

:REBOOT
reset -c

:SHUTDOWN
reset -s

:end_menu
