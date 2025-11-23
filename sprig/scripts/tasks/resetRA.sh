#!/bin/sh

. /mnt/SDCARD/sprig/scripts/helperFunctions.sh

ORIGINAL_RA_FILE="/mnt/SDCARD/RetroArch/.retroarch/retroarchV4.cfg"
BACKUP_RA_FILE="/mnt/SDCARD/RetroArch/.retroarch/retroarchV4.cfg.bak"

log_message "Resetting RetroArch config to default."
cp -f $BACKUP_RA_FILE $ORIGINAL_RA_FILE