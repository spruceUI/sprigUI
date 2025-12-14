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

preserve_sprig_config_settings() {
    log_and_display_message "Preserving sprig config settings."

    existing_config="/mnt/SDCARD/Saves/sprig/sprig-config.json"
    new_config="/mnt/SDCARD/sprigUI-$BRANCH/Saves/sprig/sprig-config.json"

    if [ -f "$existing_config" ] && [ -f "$new_config" ]; then
        python /mnt/SDCARD/App/OTA/merge_configs.py "$existing_config" "$new_config"
    fi

    # Preserve per-emulator configs
    if  [ "$OVERWRITE_EMU_DIR" = "False" ]; then
        log_and_display_message "Preserving user emu launch settings."
        for emu_dir in /mnt/SDCARD/Emu/*; do
            [ -d "$emu_dir" ] || continue

            emu_name="$(basename "$emu_dir")"

            existing_emu_config="$emu_dir/config.json"
            new_emu_config="/mnt/SDCARD/sprigUI-$BRANCH/Emu/$emu_name/config.json"

            if [ -f "$existing_emu_config" ] && [ -f "$new_emu_config" ]; then
                log_and_display_message "Preserving user emu launch settings."

                log_and_display_message "Preserving config for emulator: $emu_name"
                python /mnt/SDCARD/App/OTA/merge_configs.py \
                    "$existing_emu_config" \
                    "$new_emu_config" \
                    >> /mnt/SDCARD/Saves/sprig/sprig.log 2>&1
            fi
        done
    fi

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

delete_legacy_files_from_previous_versions(){
    if current_version_equal_or_older_than "1.1.0"; then
        rm -rf "/mnt/SDCARD/App/BoxartScraper" && log_message "Deleting /mnt/SDCARD/App/BoxartScraper"
        rm -rf "/mnt/SDCARD/App/Clock" && log_message "Deleting /mnt/SDCARD/App/Clock"
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

preserve_sprig_config_settings
if [ "$OVERWRITE_EMU_DIR" = "False" ]; then
    preserve_user_emu_launch_settings
else
    log_and_display_message "Emulator options and overrides will be reset to default."
    sleep 3
fi
complete_installation
delete_legacy_files_from_previous_versions
sync
sleep 5
reboot
