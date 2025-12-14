#!/bin/sh

. /mnt/SDCARD/sprig/scripts/helperFunctions.sh

export PATH="/mnt/SDCARD/sprig/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/sprig/lib:$LD_LIBRARY_PATH:/mnt/SDCARD/App/PyUI/libs/:/config/lib/:/customer/lib"

##### VARIABLES #####

# This controls how many MiB of free space we want to require on the SDCARD. It should be greater than
# the size of the zipfile plus the size of the contents thereof.
# sprigUI v1.0.0 release candidate size was 734 + 184 = 918 MiB.
SPACE_REQUIRED=1024

# Tweak these variables in sprig-config.json to change specific behaviors of the OTA process.
BRANCH="$(get_config_value '.menuOptions."OTA Settings".branch.selected' "release")"
BYPASS_VERSION_CHECKS="$(get_config_value '.menuOptions."OTA Settings".bypassVersionChecks.selected' "False")"
OVERWRITE_EMU_DIR="$(get_config_value '.menuOptions."OTA Settings".overwriteEmuDir.selected' "False")"
OVERWRITE_RA_CONFIGS="$(get_config_value '.menuOptions."OTA Settings".overwriteRAconfigs.selected' "False")"
OVERWRITE_PYTHON3_DIR="$(get_config_value '.menuOptions."OTA Settings".overwritePythonDir.selected' "False")"
OVERWRITE_THEMES_DIR="$(get_config_value '.menuOptions."OTA Settings".overwriteThemesDir.selected' "False")"

##########################################################

# If DELETE_BEFORE_COPY=true, delete current contents of SDCARD aside from Roms, BIOS, and Saves, to ensure full fresh install.
# This one is not accessible from sprig-config.json (yet?).
DELETE_BEFORE_COPY=false

if [ "$DELETE_BEFORE_COPY" = true ]; then
    OVERWRITE_EMU_DIR="True"
    OVERWRITE_RA_CONFIGS="True"
    OVERWRITE_PYTHON3_DIR="True"
    OVERWRITE_THEMES_DIR="True"
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
        log_and_display_message "SD card does not have $SPACE_REQUIRED MiB free. Aborting."
        return 1
    fi
}

is_wifi_connected() {
    if ping -c 3 -W 2 1.1.1.1 > /dev/null 2>&1; then
        log_message "Cloudflare ping successful; device is online."
        return 0
    else
        log_and_display_message "Cloudflare ping failed; device is offline. Aborting."
        return 1
    fi
}

is_branch_newer_than_device() {

    if [ "$BYPASS_VERSION_CHECKS" = "True" ]; then
        log_message "Bypassing version check."
        return 0
    fi

    # get version file from target branch of sprigUI repo
    cd /tmp
    if ! wget --tries=3 -O version https://raw.githubusercontent.com/spruceUI/sprigUI/$BRANCH/sprig/version ; then
        log_and_display_message "Unable to retrieve version file from $BRANCH branch of sprigUI repo. Aborting."
        return 3
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
            log_and_display_message "Device is on newer version than $BRANCH branch. Aborting."
            return 1
        # else continue to next field in the version number
        fi
    done
    log_and_display_message "Device is on same version as $BRANCH branch. No update needed. Aborting."
    return 2
}

download_target_branch() {
    cd /mnt/SDCARD
    log_and_display_message "Update found. Downloading! (~5-10min)"
    if wget --tries=3 -O "$BRANCH.zip" https://github.com/spruceUI/sprigUI/archive/refs/heads/$BRANCH.zip ; then
        log_and_display_message "Successfully downloaded $BRANCH branch zip file."
        sleep 5
        return 0
    else
        log_and_display_message "Failed to download $BRANCH branch zip file. Aborting."
        rm -f "/mnt/SDCARD/$BRANCH.zip"
        rm -rf "/mnt/SDCARD/sprigUI-$BRANCH"
        return 1
    fi
}

extract_archive() {

    log_and_display_message "Download finished. Extracting! (~4min)" 

    new_dir="sprigUI-$BRANCH"
    new_ra_dir="$new_dir/RetroArch"
    new_python3_dir="$new_dir/sprig/lib/python3.10"
    new_themes_dir="$new_dir/Themes"

    excluded_files="$new_dir/build $new_dir/justfile $new_dir/.gitignore $new_dir/.gitattributes $new_dir/TODO.txt $new_dir/miyoo/lib $new_dir/miyoo354/lib"

    if [ "$OVERWRITE_RA_CONFIGS" = "False" ]; then
        log_message "Will not overwrite RA configs."
        excluded_files="$excluded_files $new_ra_dir/config $new_ra_dir/retroarch.cfg $new_dir/Saves/NDS/config"
    fi

    if [ "$OVERWRITE_PYTHON3_DIR" = "False" ]; then
        log_message "Will not overwrite Python3.10 directory."
        excluded_files="$excluded_files $new_python3_dir"
    fi

    if [ "$OVERWRITE_THEMES_DIR" = "False" ]; then
        log_message "Will not overwrite Themes directory."
        excluded_files="$excluded_files $new_themes_dir"
    fi
    
    log_message "Files to exclude from extraction of new version: $excluded_files"

    if unzip -o "/mnt/SDCARD/$BRANCH.zip" -x $excluded_files -d /mnt/SDCARD ; then
        log_and_display_message "Archive extracted successfully."
        sleep 5
        return 0
    else
        log_and_display_message "Archive extraction failed. Aborting."
        return 1
    fi
}


##### MAIN EXECUTION #####

start_pyui_message_writer

log_and_display_message "Starting OTA process. Checking space, wifi, and version."

if does_device_have_sufficient_space && is_wifi_connected && is_branch_newer_than_device; then

    log_and_display_message "All checks passed. Proceeding to download $BRANCH branch of sprigUI repo."
    sleep 3
    
    if download_target_branch && extract_archive; then
        if [ -x "/mnt/SDCARD/sprigUI-$BRANCH/App/OTA/post_extract.sh" ]; then
            /mnt/SDCARD/sprigUI-$BRANCH/App/OTA/post_extract.sh
        else
            # rm -rf "/mnt/SDCARD/sprigUI-$BRANCH"
            log_and_display_message "post_extract.sh not found or not executable"
            exit 3
        fi
    else
        sleep 5
        exit 2
    fi

else
    sleep 5
    exit 1
fi