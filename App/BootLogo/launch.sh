#!/bin/sh

. /mnt/SDCARD/sprig/helperFunctions.sh

show /mnt/SDCARD/sprig/res/sprucetree.png
log_message "Running BootLogo app."

cd $(dirname "$0")

SUPPORTED_VERSION="202304280000" # there is no 202304280000 firmware, it's when I updated this pak originally
if [ $MIYOO_VERSION -gt $SUPPORTED_VERSION ]; then
	echo "Unknown firmware version. YOLOOOOOOOO."
	# exit 1
fi

./logoread.elf

if [ -f ./logo.jpg ]; then
	cp ./logo.jpg ./image1.jpg
else
	log_message "no logo.jpg found. Aborted."
	exit 1
fi

if ! ./logomake.elf; then
	log_message "Preparing bootlogo failed. Aborted."
	exit 1
fi

if ! ./logowrite.elf; then
	log_message "Flashing bootlogo failed. Aborted."
	exit 1
fi

log_message "Flashed bootlogo successfully. Tidying up."

rm image1.jpg
rm image2.jpg
rm image3.jpg
rm logo.img

log_message "Done."

# self-destruct
# DIR=$(dirname "$0")
# mv $DIR $DIR.disabled
