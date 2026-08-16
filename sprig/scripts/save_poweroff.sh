#!/bin/sh

. /mnt/SDCARD/sprig/scripts/helperFunctions.sh

# set up auto resume
if [ -e /tmp/cmd_to_run.sh ]; then
    cp /tmp/cmd_to_run.sh /mnt/SDCARD/sprig/flags/lastgame.lock
    log_message "cmd_to_run copied to lastgame.lock to set up autoresume"
fi

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

if is_mini_og; then
    reboot          # OG Mini hangs if you use the poweroff command
else
    # Storage-only tail for Wi-Fi Miyoo models. Keep every stock SprigUI
    # autoresume, signal, wait, and sync operation above unchanged. Closing
    # inherited standard descriptors prevents an SD-backed caller log from
    # keeping the FAT filesystem writable during the remount.
    exec </dev/null >/dev/null 2>&1
    PATH=/usr/sbin:/usr/bin:/sbin:/bin
    export PATH

    # A successful vfat RW-to-RO remount performs the same FAT clean-state
    # transition as unmount, while keeping SprigUI's bind mounts readable.
    # Verify the exact base mount after the single attempt.  On failure, use
    # the same firmware poweroff action as stock rather than leaving a frozen
    # screen that would force a dirtier hardware cut.
    sd_ro_count=0
    if mount -o remount,ro /dev/mmcblk0p1 /mnt/SDCARD; then
        while read -r sd_device sd_mount sd_type sd_options sd_rest; do
            if [ "$sd_device" = "/dev/mmcblk0p1" ] && \
                    [ "$sd_mount" = "/mnt/SDCARD" ] && \
                    [ "$sd_type" = "vfat" ]; then
                case ",$sd_options," in
                    *,ro,*) sd_ro_count=$((sd_ro_count + 1)) ;;
                esac
            fi
        done < /proc/mounts
    fi
    if [ "$sd_ro_count" -ne 1 ]; then
        /sbin/poweroff
        exit $?
    fi
    /sbin/poweroff
fi
