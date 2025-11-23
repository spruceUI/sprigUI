#!/bin/sh

. /mnt/SDCARD/spruce/scripts/helperFunctions.sh

ORIGINAL_NDS_FILE="/mnt/SDCARD/Saves/NDS/config/drastic.cfg"
BACKUP_NDS_FILE="/mnt/SDCARD/Emu/NDS/config.bak/drastic.cfg"

ORIGINAL_CF2_FILE="/mnt/SDCARD/Saves/NDS/config/drastic.cf2"
BACKUP_CF2_FILE="/mnt/SDCARD/Emu/NDS/config.bak/drastic.cf2"

log_message "Resetting DraStic config to default."
cp -f "$BACKUP_NDS_FILE" "$ORIGINAL_NDS_FILE"
cp -f "$BACKUP_CF2_FILE" "$ORIGINAL_CF2_FILE"