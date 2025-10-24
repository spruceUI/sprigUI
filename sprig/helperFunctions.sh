#!/bin/sh


##########     FLAG HANDLING     ##########

export PATH="/mnt/SDCARD/sprig/bin:/customer:$PATH"
export FLAGS_DIR="/mnt/SDCARD/sprig/flags"

# Add a flag
# Usage: flag_add "flag_name"
flag_add() {
    local flag_name="$1"
    touch "$FLAGS_DIR/${flag_name}.lock"
}

# Check if a flag exists
# Usage: flag_check "flag_name"
# Returns 0 if the flag exists (with or without .lock extension), 1 if it doesn't
flag_check() {
    local flag_name="$1"
    if [ -f "$FLAGS_DIR/${flag_name}" ] || [ -f "$FLAGS_DIR/${flag_name}.lock" ]; then
        return 0
    else
        return 1
    fi
}

# Get the full path to a flag file
# Usage: flag_path "flag_name"
# Returns the full path to the flag file (with .lock extension)
flag_path() {
    local flag_name="$1"
    echo "$FLAGS_DIR/${flag_name}.lock"
}

# Remove a flag
# Usage: flag_remove "flag_name"
flag_remove() {
    local flag_name="$1"
    rm -f "$FLAGS_DIR/${flag_name}.lock"
}


##########     LOGGING     ##########

# Call this like:
# log_message "Your message here"
# To output to a custom log file, set the variable within your script:
# log_file="/mnt/SDCARD/App/MyApp/spruce.log"
# This will log the message to the spruce.log file in the Saves/spruce folder
#
# Usage examples:
# Log a regular message:
#    log_message "This is a regular log message"
# Log a verbose message (only logged if log_verbose was called):
#    log_message "This is a verbose log message" -v
# Log to a custom file:
#    log_message "Custom file log message" "" "/path/to/custom/log.file"
# Log a verbose message to a custom file:
#    log_message "Verbose custom file log message" -v "/path/to/custom/log.file"
log_file="/mnt/SDCARD/Saves/sprig/sprig.log"
log_message() {
    message="$1"
    verbose_flag="$2"
    custom_log_file="${3:-$log_file}"

    # Check if it's a verbose message and if verbose logging is not enabled
    [ "$verbose_flag" = "-v" ] && ! flag_check "log_verbose" && return

    # Handle custom log file
    if [ "$custom_log_file" != "$log_file" ]; then
        mkdir -p "$(dirname "$custom_log_file")"
        touch "$custom_log_file"
    fi

    printf '%s%s - %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "${verbose_flag:+ -v}" "$message" | tee -a "$custom_log_file"
}

# Call this to toggle verbose logging
# After this is called, any log_message calls will output to the log file if -v is passed
# USE THIS ONLY WHEN DEBUGGING, IT WILL GENERATE A LOT OF LOG FILE ENTRIES
# Remove it from your script when done.
# Can be used as a toggle: calling it once enables verbose logging, calling it again disables it
log_verbose() {
    calling_script=$(basename "$0")
    if flag_check "log_verbose"; then
        flag_remove "log_verbose"
        log_message "Verbose logging disabled in script: $calling_script"
    else
        flag_add "log_verbose"
        log_message "Verbose logging enabled in script: $calling_script"
    fi
}

log_precise() {
    message="$1"
    date_part=$(date '+%Y-%m-%d %H:%M:%S')
    uptime_part=$(cut -d ' ' -f 1 /proc/uptime)
    timestamp="${date_part}.${uptime_part#*.}"
    printf '%s %s\n' "$timestamp" "$message" >>"$log_file"
}

rotate_logs() {
    local log_dir="/mnt/SDCARD/Saves/sprig"
    local log_target="$log_dir/sprig.log"
    local max_log_files=5

    # Create the log directory if it doesn't exist
    if [ ! -d "$log_dir" ]; then
        mkdir -p "$log_dir"
    fi

    # If sprig.log exists, move it to a temporary file
    if [ -f "$log_target" ]; then
        mv "$log_target" "$log_target.tmp"
    fi

    # Create a fresh spruce.log immediately
    touch "$log_target"

    # Perform log rotation in the background
    (
        # Rotate logs sprig5.log -> sprig4.log -> sprig3.log -> etc.
        i=$((max_log_files - 1))
        while [ $i -ge 1 ]; do
            if [ -f "$log_dir/sprig${i}.log" ]; then
                mv "$log_dir/sprig${i}.log" "$log_dir/sprig$((i+1)).log"
            fi
            i=$((i - 1))
        done

        # Move the temporary file to spruce1.log
        if [ -f "$log_target.tmp" ]; then
            mv "$log_target.tmp" "$log_dir/sprig1.log"
        fi
    ) &
}

##########     SURVIVAL     ##########

auto_regen_tmp_update() {
    tmp_dir="/mnt/SDCARD/.tmp_update"
    updater="/mnt/SDCARD/sprig/.tmp_update/runtime.sh"
    if ! flag_check "tmp_update_repair_attempted"; then
        [ ! -d "$tmp_dir" ] && mkdir "$tmp_dir" && flag_add "tmp_update_repair_attempted" && log_message ".tmp_update folder repair attempted. Adding tmp_update_repair_attempted flag."
        [ ! -f "$tmp_dir/updater" ] && cp "$updater" "$tmp_dir/updater"
    fi
}

read_only_check() {
    log_message "Performing read-only check"
    SD_or_sd=$(mount | grep -q SDCARD && echo "SDCARD" || echo "sdcard")
    log_message "Device uses /mnt/$SD_or_sd for its SD card path" -v
    MNT_LINE=$(mount | grep "$SD_or_sd")
    if [ -n "$MNT_LINE" ]; then
        log_message "mount line for SD card: $MNT_LINE" -v
        MNT_STATUS=$(echo "$MNT_LINE" | cut -d'(' -f2 | cut -d',' -f1)
        if [ "$MNT_STATUS" = "ro" ] && [ -n "$SD_DEV" ]; then
            log_message "SD card is mounted as RO. Attempting to remount."
            mount -o remount,rw "$SD_DEV" /mnt/"$SD_or_sd"
        else
            log_message "SD card is not read-only."
        fi
    fi
}



##########     CPU MANAGEMENT     ##########

CPU_DIR="/sys/devices/system/cpu/cpufreq"
POLICY_DIR="$CPU_DIR/policy0"
OD_DIR="$CPU_DIR/ondemand"

scaling_min_freq=400000
scaling_max_freq=1200000

set_smart() {
    if ! flag_check "setting_cpu"; then
        flag_add "setting_cpu"

        chmod a+w "$POLICY_DIR"/scaling_governor
        chmod a+w "$POLICY_DIR"/scaling_min_freq
        chmod a+w "$POLICY_DIR"/scaling_max_freq

        echo ondemand >"$POLICY_DIR"/scaling_governor
        echo $scaling_min_freq >"$POLICY_DIR"/scaling_min_freq
        echo $scaling_max_freq >"$POLICY_DIR"/scaling_max_freq

        echo 80 >"$OD_DIR"/up_threshold
        echo 1 >"$OD_DIR"/sampling_down_factor
        echo 400000 >"$OD_DIR"/sampling_rate

        chmod a-w "$POLICY_DIR"/scaling_governor
        chmod a-w "$POLICY_DIR"/scaling_min_freq
        chmod a-w "$POLICY_DIR"/scaling_max_freq

        log_message "CPU Mode now locked to SMART" -v
        flag_remove "setting_cpu"
    fi
}

set_performance() {
    if ! flag_check "setting_cpu"; then
        flag_add "setting_cpu"

        chmod a+w "$POLICY_DIR"/scaling_governor
        chmod a+w "$POLICY_DIR"/scaling_min_freq
        chmod a+w "$POLICY_DIR"/scaling_max_freq

        echo performance >"$POLICY_DIR"/scaling_governor
        echo $scaling_max_freq >"$POLICY_DIR"/scaling_min_freq # not a typo. we lockin' it.
        echo $scaling_max_freq >"$POLICY_DIR"/scaling_max_freq

        chmod a-w "$POLICY_DIR"/scaling_governor
        chmod a-w "$POLICY_DIR"/scaling_min_freq
        chmod a-w "$POLICY_DIR"/scaling_max_freq

        log_message "CPU Mode now locked to PERFORMANCE" -v
        flag_remove "setting_cpu"
    fi
}

##########     OTHER STUFF     ##########

show() {
    /customer/app/sdldisplay "$1"
}

vibrate() {
    /mnt/SDCARD/sprig/scripts/vibrate.sh "$1" &
}
