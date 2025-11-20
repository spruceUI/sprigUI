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

CURRENT_VERSION="$(cat /mnt/SDCARD/sprig/version)"

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
        excluded_files="$excluded_files $new_ra_dir/config $new_ra_dir/retroarchV4.cfg $new_dir/Saves/NDS/config"
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

preserve_user_emu_launch_settings() {
    log_and_display_message "Preserving user emu launch settings."
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

preserve_sprig_config_settings() {
    log_and_display_message "Preserving sprig config settings."

    existing_config="/mnt/SDCARD/Saves/sprig/sprig-config.json"
    new_config="/mnt/SDCARD/sprigUI-$BRANCH/Saves/sprig/sprig-config.json"
    python /mnt/SDCARD/App/OTA/merge_configs.py "$existing_config" "$new_config"
}

current_version_equal_or_older_than() {
    # $1 = version to compare against

    IFS='.' read -r c1 c2 c3 <<EOF
$CURRENT_VERSION
EOF
    IFS='.' read -r v1 v2 v3 <<EOF
$1
EOF

    # Default missing fields to zero
    c1=${c1:-0}; c2=${c2:-0}; c3=${c3:-0}
    v1=${v1:-0}; v2=${v2:-0}; v3=${v3:-0}

    # Compare major
    if [ "$c1" -lt "$v1" ]; then return 0; fi
    if [ "$c1" -gt "$v1" ]; then return 1; fi

    # Compare minor
    if [ "$c2" -lt "$v2" ]; then return 0; fi
    if [ "$c2" -gt "$v2" ]; then return 1; fi

    # Compare patch
    if [ "$c3" -le "$v3" ]; then return 0; fi

    return 1
}

delete_extra_files_from_old_releases(){
    if current_version_equal_or_older_than "1.1.0"; then
        echo "Deleting /mnt/SDCARD/App/BoxartScraper"
        rm -rf "/mnt/SDCARD/App/BoxartScraper"
    fi
}

complete_installation() {

    log_message "Killing main execution loop, powerbutton watchdog, and SSH."
    killall -9 main button_watchdog.sh lid_watchdog.sh dropbearmulti # adbd    ### Keep adbd on for testing
    for dir in /etc/profile \
                /etc/passwd \
                /etc/group \
                /mnt/SDCARD/Emu/OPENBOR/Saves \
                /mnt/SDCARD/Emu/NDS/backup \
                /mnt/SDCARD/Emu/NDS/config \
                /mnt/SDCARD/Emu/NDS/savestates ; do
        umount "$dir" >/dev/null 2>&1
    done

    if [ "$DELETE_BEFORE_COPY" = true ]; then
        for dir in App Emu miyoo285 RetroArch sprig Themes RApp; do
            rm -rf /mnt/SDCARD/$dir
            log_message "Deleted old $dir directory."
        done
    fi

    log_and_display_message "Copying new sprigUI version into place (~5min)"
    cp -rf /mnt/SDCARD/sprigUI-"$BRANCH"/* /mnt/SDCARD

    log_and_display_message "Installation complete. Cleaning up temporary files (~2min)"
    rm -rf "/mnt/SDCARD/$BRANCH.zip" "/mnt/SDCARD/sprigUI-$BRANCH"

    log_and_display_message "Update finished. Syncing and rebooting! happy gaming.........."
}

##### MAIN EXECUTION #####

start_pyui_message_writer

log_and_display_message "Starting OTA process. Checking space, wifi, and version."

if does_device_have_sufficient_space && is_wifi_connected && is_branch_newer_than_device; then

    log_and_display_message "All checks passed. Proceeding to download $BRANCH branch of sprigUI repo."
    sleep 3
    
    if download_target_branch && extract_archive; then
        preserve_sprig_config_settings
        if [ "$OVERWRITE_EMU_DIR" = "False" ]; then
            preserve_user_emu_launch_settings
        else
            log_and_display_message "Emulator options and overrides will be reset to default."
            sleep 3
        fi
        complete_installation
        delete_extra_files_from_old_releases
        sync
        sleep 5
        reboot
    else
        sleep 5
        exit 2
    fi

else
    sleep 5
    exit 1
fi