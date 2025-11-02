#!/bin/sh

. /mnt/SDCARD/sprig/helperFunctions.sh

# kill the loop first so mainui doesn't try to relaunch
killall -q -9 main

EMU_LIST="MainUI retroarch scummvm drastic OpenBOR OpenBOR_mod OpenBOR_new pico8_dyn ffplay DinguxCommander reader "

for emulator in $EMU_LIST; do
    killall -q -15 "$emulator"
    while killall -q -0 "$emulator"; do
        sleep 0.1
    done
done

sync
poweroff