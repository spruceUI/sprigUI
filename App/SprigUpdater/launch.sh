#!/bin/sh

. /mnt/SDCARD/sprig/helperFunctions.sh

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

    # Check if local archive exists - skip version check if it does
    for archive in /mnt/SDCARD/*.zip /mnt/SDCARD/*.7z; do
        if [ -f "$archive" ]; then
            log_message "Local archive found. Skipping online version check."
            return 0
        fi
    done

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
    
    # Check for any zip or 7z file in root of SD card
    local_archive=""
    local_archive_type=""
    for archive in /mnt/SDCARD/*.zip /mnt/SDCARD/*.7z; do
        if [ -f "$archive" ]; then
            local_archive="$archive"
            case "$archive" in
                *.7z) local_archive_type="7z" ;;
                *.zip) local_archive_type="zip" ;;
            esac
            log_and_display_message "Found local archive: $(basename "$archive")"
            break
        fi
    done
    
    if [ -n "$local_archive" ]; then
        log_and_display_message "Using local archive for update."
        # Store the archive type for extraction
        echo "$local_archive_type" > /tmp/archive_type
        # Keep original filename but ensure we know where it is
        if [ "$local_archive" != "/mnt/SDCARD/update_archive.$local_archive_type" ]; then
            cp "$local_archive" "/mnt/SDCARD/update_archive.$local_archive_type"
            log_message "Copied local archive to update_archive.$local_archive_type"
        fi
        sleep 3
        return 0
    fi
    
    # If no local file found, download from GitHub
    log_and_display_message "No local archive found. Downloading! (~5-10min)"
    echo "zip" > /tmp/archive_type
    if wget --tries=3 -O "update_archive.zip" https://github.com/spruceUI/sprigUI/archive/refs/heads/$BRANCH.zip ; then
        log_and_display_message "Successfully downloaded $BRANCH branch zip file."
        sleep 5
        return 0
    else
        log_and_display_message "Failed to download $BRANCH branch zip file. Aborting."
        rm -f "/mnt/SDCARD/update_archive.zip"
        rm -rf "/mnt/SDCARD/sprigUI-$BRANCH"
        return 1
    fi
}

extract_archive() {

    log_and_display_message "Download finished. Extracting! (~4min)" 

    # Determine archive type
    archive_type="$(cat /tmp/archive_type 2>/dev/null || echo 'zip')"
    archive_file="/mnt/SDCARD/update_archive.$archive_type"
    
    cd /mnt/SDCARD
    
    # Extract based on archive type
    if [ "$archive_type" = "7z" ]; then
        log_message "Extracting 7z archive"
        if 7zr x -y "$archive_file" -o/mnt/SDCARD ; then
            log_and_display_message "Archive extracted successfully."
            # Find the extracted directory (it will be named sprigUI-<something> or sprigV<version>)
            extracted_dir=$(find /mnt/SDCARD -maxdepth 1 -type d -name "sprig*" ! -path "/mnt/SDCARD/sprig" | head -1)
            if [ -d "$extracted_dir" ]; then
                # Rename to expected format
                mv "$extracted_dir" "/mnt/SDCARD/sprigUI-$BRANCH"
                log_message "Renamed $(basename "$extracted_dir") to sprigUI-$BRANCH"
            fi
        else
            log_and_display_message "Archive extraction failed. Aborting."
            return 1
        fi
    else
        log_message "Extracting zip archive"
        
        new_dir="sprigUI-$BRANCH"
        new_ra_dir="$new_dir/RetroArch"
        new_python3_dir="$new_dir/App/PyUI/python3.10"
        new_themes_dir="$new_dir/Themes"

        excluded_files="$new_dir/build $new_dir/justfile $new_dir/.gitignore $new_dir/.gitattributes $new_dir/TODO.txt"

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

        if unzip -o "$archive_file" -x $excluded_files -d /mnt/SDCARD ; then
            log_and_display_message "Archive extracted successfully."
        else
            log_and_display_message "Archive extraction failed. Aborting."
            return 1
        fi
    fi
    
    # Handle exclusions for 7z files by removing unwanted files after extraction
    if [ "$archive_type" = "7z" ]; then
        new_dir="sprigUI-$BRANCH"
        if [ "$OVERWRITE_RA_CONFIGS" = "False" ]; then
            log_message "Removing extracted RA configs to preserve existing ones."
            rm -rf "/mnt/SDCARD/$new_dir/RetroArch/config" \
                   "/mnt/SDCARD/$new_dir/RetroArch/retroarchV4.cfg" \
                   "/mnt/SDCARD/$new_dir/Saves/NDS/config"
        fi
        if [ "$OVERWRITE_PYTHON3_DIR" = "False" ]; then
            log_message "Removing extracted Python directory to preserve existing one."
            rm -rf "/mnt/SDCARD/$new_dir/App/PyUI/python3.10"
        fi
        if [ "$OVERWRITE_THEMES_DIR" = "False" ]; then
            log_message "Removing extracted Themes directory to preserve existing one."
            rm -rf "/mnt/SDCARD/$new_dir/Themes"
        fi
        # Always remove build files
        rm -rf "/mnt/SDCARD/$new_dir/build" \
               "/mnt/SDCARD/$new_dir/justfile" \
               "/mnt/SDCARD/$new_dir/.gitignore" \
               "/mnt/SDCARD/$new_dir/.gitattributes" \
               "/mnt/SDCARD/$new_dir/TODO.txt"
    fi
    
    sleep 5
    return 0
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
    /mnt/SDCARD/App/PyUI/python3.10/bin/python3.10 /mnt/SDCARD/App/SprigUpdater/merge_configs.py "$existing_config" "$new_config"
}

complete_installation() {

    log_message "Killing main execution loop, powerbutton watchdog, and SSH."
    killall -9 main button_watchdog.sh dropbearmulti # adbd    ### Keep adbd on for testing
    umount /etc/profile >/dev/null 2>&1
	umount /mnt/SDCARD/Emu/OPENBOR/Saves >/dev/null 2>&1


    if [ "$DELETE_BEFORE_COPY" = true ]; then
        for dir in App Emu miyoo285 RetroArch sprig Themes RApp; do
            rm -rf /mnt/SDCARD/$dir
            log_message "Deleted old $dir directory."
        done
    fi

    log_and_display_message "Copying new sprigUI version into place (~5min)"
    cp -rf /mnt/SDCARD/sprigUI-"$BRANCH"/* /mnt/SDCARD

    log_and_display_message "Installation complete. Cleaning up temporary files (~2min)"
    rm -rf "/mnt/SDCARD/update_archive.zip" "/mnt/SDCARD/update_archive.7z" "/mnt/SDCARD/sprigUI-$BRANCH"
    
    # Clean up any other zip or 7z files in root
    for archive in /mnt/SDCARD/*.zip /mnt/SDCARD/*.7z; do
        if [ -f "$archive" ]; then
            rm -f "$archive"
            log_message "Removed $(basename "$archive")"
        fi
    done

    log_and_display_message "Update finished. Syncing and rebooting! happy gaming.........."
}

##### MAIN EXECUTION #####

start_pyui_message_writer

log_and_display_message "Starting update process. Checking requirements."

# Check if any zip or 7z file exists in root of SD card
local_archive_exists=false
for archive in /mnt/SDCARD/*.zip /mnt/SDCARD/*.7z; do
    if [ -f "$archive" ]; then
        local_archive_exists=true
        log_message "Local archive detected. Will skip wifi check."
        break
    fi
done

# Run checks based on whether we have a local archive
if [ "$local_archive_exists" = true ]; then
    # Only check space and version when using local file
    if does_device_have_sufficient_space && is_branch_newer_than_device; then
        log_and_display_message "All checks passed. Proceeding with local update file."
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
else
    # Check space, wifi, and version for download
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
fi