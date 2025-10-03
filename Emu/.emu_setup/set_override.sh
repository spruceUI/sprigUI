#!/bin/sh

##### DEFINE BASE VARIABLES #####

. /mnt/SDCARD/spruce/scripts/helperFunctions.sh
log_message "--- Setting per-game launch options ---"

EMU_NAME="$(echo "$1" | cut -d'/' -f5)"
GAME="$(basename "$1")"
OPT_DIR="/mnt/SDCARD/Emu/.emu_setup/options"
OVR_DIR="/mnt/SDCARD/Emu/.emu_setup/overrides"
OPT_FILE="$OPT_DIR/${EMU_NAME}.opt"
OVR_FILE="$OVR_DIR/$EMU_NAME/$GAME.opt"

##### IMPORT .OPT FILES #####
if [ -f "$OPT_FILE" ]; then
	if [ ! -d "$OVR_DIR/$EMU_NAME" ]; then
		mkdir "$OVR_DIR/$EMU_NAME"
	fi
	cp -f "$OPT_FILE" "$OVR_FILE" &
	log_message "Current system options saved as override for $GAME."
	. "$OVR_FILE"
	display -d 2 -t "Setting $CORE core and $MODE mode as override for $GAME."
else
	log_message "ERROR: no system options file found for $EMU_NAME". Override could not be created.
	display -d 2 -t "Error: Override could not be created."
fi
