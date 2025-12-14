#!/bin/sh

. /mnt/SDCARD/sprig/scripts/helperFunctions.sh

ORIGINAL_RA_FILE="/mnt/SDCARD/RetroArch/.retroarch/retroarch.cfg"
BACKUP_RA_FILE="/mnt/SDCARD/RetroArch/.retroarch/retroarch.cfg.bak"

log_message "Resetting RetroArch config to default."
cp -f $BACKUP_RA_FILE $ORIGINAL_RA_FILE