#!/bin/sh

. /mnt/SDCARD/sprig/scripts/helperFunctions.sh

start_pyui_message_writer
sleep 1
log_and_display_message "Flashing bootlogo! Please do not power off."
sleep 3

cd $(dirname "$0")

SUPPORTED_VERSION="202304280000" # there is no 202304280000 firmware, it's when I updated this pak originally
if [ $MIYOO_VERSION -gt $SUPPORTED_VERSION ]; then
	log_message "Unknown firmware version. YOLOOOOOOOO."
	# exit 1
fi

./logoread.elf

if [ -f ./logo.jpg ]; then
	cp ./logo.jpg ./image1.jpg
else
	log_and_display_message "No logo.jpg found. Aborted."
	sleep 5
	exit 1
fi

if ! ./logomake.elf; then
	log_and_display_message "Preparing bootlogo failed. Aborted."
	sleep 5
	exit 1
fi

if ! ./logowrite.elf; then
	log_and_display_message "Flashing bootlogo failed. Aborted."
	sleep 5
	exit 1
fi

log_message "Flashed bootlogo successfully. Tidying up."

rm image1.jpg
rm image2.jpg
rm image3.jpg
rm logo.img

log_and_display_message "Done."
sleep 3
stop_pyui_message_writer

