#!/bin/sh

. /mnt/SDCARD/sprig/helperFunctions.sh

export PATH="/mnt/SDCARD/sprig/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/sprig/lib:$LD_LIBRARY_PATH"

##### VARIABLES #####

# Tweak these variables to change specific behaviors of the OTA process.

# Change this to change which branch of the repo to download. 'developer.lock' overrides this to the "Development" branch.
BRANCH=main

# This controls how many MiB of free space we want to require on the SDCARD. It should be greater than
# the size of the zipfile plus the size of the contents thereof.
SPACE_REQUIRED=800

# Will not copy certain files and folders into place if set to false. DELETE_BEFORE_COPY overrides these all to true.
OVERWRITE_EMU_DIR=false
OVERWRITE_RA_CONFIGS=false
OVERWRITE_PYTHON3_DIR=false
OVERWRITE_THEMES_DIR=true

# If true, delete current contents of SDCARD aside from Roms, BIOS, and Saves, to ensure full fresh install.
DELETE_BEFORE_COPY=false


##########################################################

if flag_check "developer"; then BRANCH=Development ; fi

if [ "$DELETE_BEFORE_COPY" = true ]; then
    OVERWRITE_EMU_DIR=true
    OVERWRITE_RA_CONFIGS=true
    OVERWRITE_PYTHON3_DIR=true
    OVERWRITE_THEMES_DIR=true
fi

##########################################################


##### FUNCTION DEFINITIONS #####

does_device_have_sufficient_space() {
    FREE_SPACE="$(df -m /mnt/SDCARD | awk '{print $4}' | tail -n 1)"
    log_message "Free space on SDCARD: $FREE_SPACE MiB"
    log_message "Space required for safe update: $SPACE_REQUIRED MiB"
    if [ "$FREE_SPACE" -ge "$SPACE_REQUIRED" ]; then
        log_message "SD card has sufficient space. Continuing."
        return 0
    else
        log_message "SD card does not have $SPACE_REQUIRED MiB free. Aborting."
        /mnt/SDCARD/App/PyUI/launch.sh -msgDisplay "SD card does not have $SPACE_REQUIRED MiB free. Aborting" -msgDisplayTimeMs 3000
        return 1
    fi
}

is_wifi_connected() {
    if ping -c 3 -W 2 1.1.1.1 > /dev/null 2>&1; then
        log_message "Cloudflare ping successful; device is online."
        return 0
    else
        log_message "Cloudflare ping failed; device is offline. Aborting."
        /mnt/SDCARD/App/PyUI/launch.sh -msgDisplay "Cloudflare ping failed; device is offline. Aborting." -msgDisplayTimeMs 3000
        return 1
    fi
}

is_branch_newer_than_device() {

    # get version file from target branch of sprigUI repo
    cd /tmp
    if ! wget --tries=3 -O version https://raw.githubusercontent.com/spruceUI/sprigUI/$BRANCH/sprig/version ; then
        log_message "Unable to retrieve version file from $BRANCH branch of sprigUI repo. Aborting."
        /mnt/SDCARD/App/PyUI/launch.sh -msgDisplay "Unable to retrieve version file from $BRANCH branch of sprigUI repo. Aborting." -msgDisplayTimeMs 3000
        return 1
    fi

    # put the contents of the two version files to compare into variables
    branch_version="$(tr -d ' \n\r' < /tmp/version)"
    device_version="$(tr -d ' \n\r' < /mnt/SDCARD/sprig/version)"

    [ -z "$device_version" ] && device_version="0.0.0"  # allow OTA if version file missing

    log_message "$BRANCH branch is on version $branch_version."
    log_message "Current installation is on version $device_version."

    # split the versions into 3 numbers each for comparison
    A_1=$(echo "$branch_version" | cut -d. -f1)
    A_2=$(echo "$branch_version" | cut -d. -f2)
    A_3=$(echo "$branch_version" | cut -d. -f3)

    B_1=$(echo "$device_version" | cut -d. -f1)
    B_2=$(echo "$device_version" | cut -d. -f2)
    B_3=$(echo "$device_version" | cut -d. -f3)

    # compare major, minor, and patch versions one by one. Return 0 if target branch version is newer.
    for i in 1 2 3; do
        eval A=\$A_$i
        eval B=\$B_$i
        if [ "$A" -gt "$B" ]; then 
            log_message "Branch version is newer. Proceeding with update."
            return 0
        elif [ "$A" -lt "$B" ]; then
            log_message "Device is on newer version than $BRANCH branch. Aborting."
            /mnt/SDCARD/App/PyUI/launch.sh -msgDisplay "Device is on newer version than $BRANCH branch. Aborting." -msgDisplayTimeMs 3000
            return 1
        # else continue to next field in the version number
        fi
    done
    log_message "Device is on same version as $BRANCH branch. No update needed. Aborting."
    /mnt/SDCARD/App/PyUI/launch.sh -msgDisplay "Device is on same version as $BRANCH branch. No update needed. Aborting." -msgDisplayTimeMs 3000
    return 1
}

download_target_branch() {
    cd /mnt/SDCARD
    /mnt/SDCARD/App/PyUI/launch.sh -msgDisplay "Update found, beginning download. (~5min)" -msgDisplayTimeMs 1 &
    if wget --tries=3 -O "$BRANCH.zip" https://github.com/spruceUI/sprigUI/archive/refs/heads/$BRANCH.zip ; then
        log_message "Successfully downloaded $BRANCH branch zip file."
        return 0
    else
        log_message "Failed to download $BRANCH branch zip file. Aborting."
        rm -f "/mnt/SDCARD/$BRANCH.zip"
        rm -rf "/mnt/SDCARD/sprigUI-$BRANCH"
        /mnt/SDCARD/App/PyUI/launch.sh -msgDisplay "Failed to download $BRANCH branch zip file. Aborting." -msgDisplayTimeMs 3000
        return 1
    fi
}

extract_archive() {

    /mnt/SDCARD/App/PyUI/launch.sh -msgDisplay "Download finished, beginning extraction (~4min)" -msgDisplayTimeMs 1 &

    new_dir="sprigUI-$BRANCH"
    new_ra_dir="$new_dir/RetroArch"
    new_python3_dir="$new_dir/App/PyUI/python3.10"
    new_themes_dir="$new_dir/Themes"

    excluded_files="$new_dir/create_sprig_release.sh $new_dir/create_sprig_release.bat $new_dir/TODO.txt"

    if [ "$OVERWRITE_RA_CONFIGS" = false ]; then
        log_message "Will not overwrite RA configs."
        excluded_files="$excluded_files $new_ra_dir/config $new_ra_dir/retroarchV4.cfg"
    fi

    if [ "$OVERWRITE_PYTHON3_DIR" = false ]; then
        log_message "Will not overwrite Python3.10 directory."
        excluded_files="$excluded_files $new_python3_dir"
    fi

    if [ "$OVERWRITE_THEMES_DIR" = false ]; then
        log_message "Will not overwrite Themes directory."
        excluded_files="$excluded_files $new_themes_dir"
    fi
    
    log_message "Files to exclude from extraction of new version: $excluded_files"

    if unzip -o "/mnt/SDCARD/$BRANCH.zip" -x $excluded_files -d /mnt/SDCARD ; then
        log_message "Archive extracted successfully."
        return 0
    else
        log_message "Archive extraction failed. Aborting."
        /mnt/SDCARD/App/PyUI/launch.sh -msgDisplay "Archive extraction failed. Aborting." -msgDisplayTimeMs 3000
        return 1
    fi
}

preserve_user_emu_launch_settings() {
    log_message "Preserving user emu launch settings."
    for configjson in /mnt/SDCARD/Emu/*/config.json ; do

        emu_dir="$(dirname "$configjson")"
        emu_name="$(basename "$emu_dir")"
        new_json="/mnt/SDCARD/sprigUI-$BRANCH/Emu/$emu_name/config.json"

        [ -f "$new_json" ] || continue    # Skip if new config doesn’t exist

        if jq -e '.menuOptions.Emulator' "$new_json" >/dev/null; then
            selected_core="$(jq -r '.menuOptions.Emulator.selected' "$configjson")"
            overrides="$(jq '.menuOptions.Emulator.overrides' "$configjson")"
            [ "$overrides" = "null" ] && overrides='{}'
            log_message "$emu_name: selected core: $selected_core"
            log_message "$emu_name: overrides section: $overrides"
            tmpfile="$(mktemp)"
            jq \
                --arg selected "$selected_core" \
                --argjson overrides "$overrides" \
                '.menuOptions.Emulator.selected = $selected
                | .menuOptions.Emulator.overrides = $overrides' \
                "$new_json" > "$tmpfile" && mv -f "$tmpfile" "$new_json"
        fi
    done
}

complete_installation() {

    log_message "Killing main execution loop, powerbutton watchdog, and SSH."
    killall -9 main button_watchdog.sh dropbearmulti # adbd    ### Keep adbd on for testing
    umount /etc/profile >/dev/null 2>&1

    if [ "$DELETE_BEFORE_COPY" = true ]; then
        for dir in App Emu miyoo285 RetroArch sprig Themes RApp; do
            rm -rf /mnt/SDCARD/$dir
            log_message "Deleted old $dir directory."
        done
    fi

    /mnt/SDCARD/App/PyUI/launch.sh -msgDisplay "Copying new sprigUI version into place (~5min)" -msgDisplayTimeMs 1 &
    log_message "Copying new sprigUI version into place."
    cp -rf /mnt/SDCARD/sprigUI-"$BRANCH"/* /mnt/SDCARD

    log_message "Installation complete. Cleaning up. (~2min)"
    /mnt/SDCARD/App/PyUI/launch.sh -msgDisplay "Cleaning up temporary files " -msgDisplayTimeMs 1 &
    rm -rf "/mnt/SDCARD/$BRANCH.zip" "/mnt/SDCARD/sprigUI-$BRANCH"

    log_message "Update finished. Syncing and rebooting! happy gaming.........."
    /mnt/SDCARD/App/PyUI/launch.sh -msgDisplay "Update finished. Syncing and rebooting! happy gaming.........." -msgDisplayTimeMs 3000
}

##### MAIN EXECUTION #####

log_message "Starting OTA process. Checking space, wifi, and version."
/mnt/SDCARD/App/PyUI/launch.sh -msgDisplay "Starting OTA process. Checking space, wifi, and version" -msgDisplayTimeMs 1000
# show /mnt/SDCARD/sprig/res/sprucetree.png

if does_device_have_sufficient_space && is_wifi_connected && is_branch_newer_than_device; then

    log_message "All checks passed. Proceeding to download $BRANCH branch of sprigUI repo."
    
    if download_target_branch && extract_archive; then
        if [ "$OVERWRITE_EMU_DIR" = false ]; then
            preserve_user_emu_launch_settings
        else
            log_message "Emulator options and overrides will be reset to default."
        fi
        complete_installation
        sync
        /mnt/SDCARD/App/PyUI/launch.sh -msgDisplay "Update finished, rebooting" -msgDisplayTimeMs 1 &

        reboot
    else
        exit 2
    fi

else
    exit 1
fi