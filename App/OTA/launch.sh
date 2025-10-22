#!/bin/sh

. /mnt/SDCARD/sprig/helperFunctions.sh

show /mnt/SDCARD/sprig/res/logo.jpg

does_device_have_sufficient_space() {
    FREE_SPACE="$(df -m /mnt/SDCARD | awk '{print $4}' | tail -n 1)"
    SPACE_REQUIRED=700
    log_message "Free space on SDCARD: $FREE_SPACE MiB"
    log_message "Space required for safe update: $SPACE_REQUIRED MiB"
    if [ "$FREE_SPACE" -ge "$SPACE_REQUIRED" ]; then
        log_message "SD card has sufficient space. Continuing."
        return 0
    else
        log_message "SD card does not have $SPACE_REQUIRED MiB free. Aborting."
        return 1
    fi
}

is_wifi_connected() {
    if ping -c 3 -W 2 1.1.1.1 > /dev/null 2>&1; then
        log_message "Cloudflare ping successful; device is online."
        return 0
    else
        log_message "Cloudflare ping failed; device is offline. Aborting."
        return 1
    fi
}

is_main_branch_newer_than_device() {

    # get version file from main branch of sprigUI repo
    cd /tmp
    if ! wget --tries=3 -O version https://raw.githubusercontent.com/spruceUI/sprigUI/main/sprig/version ; then
        log_message "Unable to retrieve version file from main branch of sprigUI repo. Aborting."
        return 1
    fi

    # put the contents of the two version files to compare into variables
    main_branch_version="$(cat /tmp/version)"
    device_version="$(cat /mnt/SDCARD/sprig/version)"

    # split the versions into 3 numbers each for comparison
    IFS=. read -r A_1 A_2 A_3 <<< "$main_branch_version"
    IFS=. read -r B_1 B_2 B_3 <<< "$device_version"

    # compare major, minor, and patch versions one by one. Return 0 if main branch version is newer.
    for i in 1 2 3; do
        eval A=\$A_$i
        eval B=\$B_$i
        if [ "$A" -gt "$B" ]; then 
            return 0
        elif [ "$A" -lt "$B" ]; then
            return 1
        # else continue to next field in the version number
        fi
    done
    return 1
}


##### MAIN EXECUTION #####

log_message "Starting OTA process. Checking space, wifi, and version."

if does_device_have_sufficient_space && is_wifi_connected && is_main_branch_newer_than_device; then

    log_message "All checks passed. Proceeding to download main branch of sprigUI repo."
    
    cd /mnt/SDCARD
    if wget --tries=3 -O main.zip https://github.com/spruceUI/sprigUI/archive/refs/heads/main.zip ; then
        log_message "Successfully downloaded main branch zip file."
    else
        log_message "Failed to download main branch zip file. Aborting."
        exit 1
    fi

    if unzip -o /mnt/SDCARD/main.zip App/* Emu/.emu_setup/* miyoo285/* RetroArch/* sprig/* Themes/* LICENSE README.md -d /mnt/SDCARD ; then
        log_message "Update successful! Rebooting."
        reboot
    else
        log_message "Update failed! Rebooting. Godspeed."
        reboot
    fi  

else
    exit 1
fi