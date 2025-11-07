#!/bin/sh

# Gain access to these functions in your script by adding the following line at the top:
# . /mnt/SDCARD/sprig/helperFunctions.sh

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
# log_file="/mnt/SDCARD/App/MyApp/sprig.log"
# This will log the message to the sprig.log file in the Saves/sprig folder
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

    # Create a fresh sprig.log immediately
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

        # Move the temporary file to sprig1.log
        if [ -f "$log_target.tmp" ]; then
            mv "$log_target.tmp" "$log_dir/sprig1.log"
        fi
    ) &
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

        echo ondemand >"$POLICY_DIR"/scaling_governor
        echo $scaling_min_freq >"$POLICY_DIR"/scaling_min_freq
        echo $scaling_max_freq >"$POLICY_DIR"/scaling_max_freq

        echo 85 >"$OD_DIR"/up_threshold
        echo 1 >"$OD_DIR"/sampling_down_factor
        echo 400000 >"$OD_DIR"/sampling_rate

        log_message "CPU Mode now set to SMART" -v
        flag_remove "setting_cpu"
    fi
}

set_performance() {
    if ! flag_check "setting_cpu"; then
        flag_add "setting_cpu"

        echo performance >"$POLICY_DIR"/scaling_governor
        echo $scaling_max_freq >"$POLICY_DIR"/scaling_min_freq # not a typo. we lockin' it.
        echo $scaling_max_freq >"$POLICY_DIR"/scaling_max_freq

        log_message "CPU Mode now set to PERFORMANCE" -v
        flag_remove "setting_cpu"
    fi
}

##########     VOLUME CONTROL     ##########

MIN_RAW_VOLUME=-60
MAX_RAW_VOLUME=30
MAX_VOLUME=20

# Set volume level (0-20)
# Usage: set_volume 15
set_volume() {
    local volume="$1"
    
    # Clamp volume between 0 and MAX_VOLUME
    [ "$volume" -lt 0 ] && volume=0
    [ "$volume" -gt "$MAX_VOLUME" ] && volume="$MAX_VOLUME"
    
    # Save volume to config
    set_pyui_config_value ".vol" "$volume"
    
    # Calculate raw volume using logarithmic curve
    local volume_raw=0
    if [ "$volume" -ne 0 ]; then
        # Using integer arithmetic: volume_raw = round(48 * log10(1 + volume))
        # Approximation using lookup table for integer math
        case "$volume" in
            1) volume_raw=-44 ;;
            2) volume_raw=-37 ;;
            3) volume_raw=-32 ;;
            4) volume_raw=-29 ;;
            5) volume_raw=-26 ;;
            6) volume_raw=-24 ;;
            7) volume_raw=-22 ;;
            8) volume_raw=-20 ;;
            9) volume_raw=-18 ;;
            10) volume_raw=-17 ;;
            11) volume_raw=-15 ;;
            12) volume_raw=-14 ;;
            13) volume_raw=-13 ;;
            14) volume_raw=-12 ;;
            15) volume_raw=-11 ;;
            16) volume_raw=-10 ;;
            17) volume_raw=-9 ;;
            18) volume_raw=-8 ;;
            19) volume_raw=-7 ;;
            20) volume_raw=-6 ;;
            *) volume_raw="$MIN_RAW_VOLUME" ;;
        esac
    else
        volume_raw="$MIN_RAW_VOLUME"
    fi
    
    # Apply volume using hardware interface
    set_volume_raw "$volume_raw"
    
    log_message "Volume set to $volume (raw: ${volume_raw}dB)" -v
}

# Set raw hardware volume
# Usage: set_volume_raw -20
set_volume_raw() {
    local volume_raw="$1"
    
    # Clamp to hardware limits
    [ "$volume_raw" -lt "$MIN_RAW_VOLUME" ] && volume_raw="$MIN_RAW_VOLUME"
    [ "$volume_raw" -gt "$MAX_RAW_VOLUME" ] && volume_raw="$MAX_RAW_VOLUME"
    
    # Set volume via hardware interface
    if [ -e /proc/mi_modules/mi_ao/mi_ao0 ]; then
        echo "set_ao_volume 0 ${volume_raw}dB" > /proc/mi_modules/mi_ao/mi_ao0 2>/dev/null
        echo "set_ao_volume 1 ${volume_raw}dB" > /proc/mi_modules/mi_ao/mi_ao0 2>/dev/null
        
        # Handle mute state
        if [ "$volume_raw" -le "$MIN_RAW_VOLUME" ]; then
            echo "set_ao_mute 1" > /proc/mi_modules/mi_ao/mi_ao0 2>/dev/null
        else
            echo "set_ao_mute 0" > /proc/mi_modules/mi_ao/mi_ao0 2>/dev/null
        fi
    fi
}

# Increase volume
# Usage: volume_up
volume_up() {
    local current_volume
    current_volume=$(get_pyui_config_value ".vol" 10)
    local new_volume=$((current_volume + 1))
    set_volume "$new_volume"
}

# Decrease volume
# Usage: volume_down
volume_down() {
    local current_volume
    current_volume=$(get_pyui_config_value ".vol" 10)
    local new_volume=$((current_volume - 1))
    set_volume "$new_volume"
}


##########     BACKLIGHT CONTROL     ##########

DUTY_CYCLE_PATH="/sys/class/pwm/pwmchip0/pwm0/duty_cycle"
MIN_RAW_BACKLIGHT=3
MAX_RAW_BACKLIGHT=100
MAX_BACKLIGHT=10


# Set backlight level (0-10)
# Usage: set_backlight 5
set_backlight() {
    local backlight="$1"
    
    # Clamp backlight between 0 and MAX_BACKLIGHT
    [ "$backlight" -lt 0 ] && backlight=0
    [ "$backlight" -gt "$MAX_BACKLIGHT" ] && backlight="$MAX_BACKLIGHT"
    
    # Save backlight to config
    set_pyui_config_value ".backlight" "$backlight"

    # Calculate raw backlight
    local backlight_raw=0
    if [ "$backlight" -ne 0 ]; then
        case "$backlight" in
            1) backlight_raw=4 ;;
            2) backlight_raw=5 ;;
            3) backlight_raw=8 ;;
            4) backlight_raw=13 ;;
            5) backlight_raw=20 ;;
            6) backlight_raw=30 ;;
            7) backlight_raw=45 ;;
            8) backlight_raw=60 ;;
            9) backlight_raw=80 ;;
            10) backlight_raw=100 ;;
            *) backlight_raw="$MIN_RAW_BACKLIGHT" ;;
        esac
    else
        backlight_raw="$MIN_RAW_BACKLIGHT"
    fi
    
    # Apply backlight setting using hardware interface
    set_backlight_raw "$backlight_raw"
    
    log_message "Backlight set to $backlight (raw: ${backlight_raw}% duty cycle)" -v
}

# Set raw hardware backlight
# Usage: set_backlight_raw 60
set_backlight_raw() {
    local backlight_raw="$1"
    
    # Clamp to hardware limits
    [ "$backlight_raw" -lt "$MIN_RAW_BACKLIGHT" ] && backlight_raw="$MIN_RAW_BACKLIGHT"
    [ "$backlight_raw" -gt "$MAX_RAW_BACKLIGHT" ] && backlight_raw="$MAX_RAW_BACKLIGHT"
    
    echo $backlight_raw > "$DUTY_CYCLE_PATH"
}

# Increase backlight
# Usage: backlight_up
backlight_up() {
    local current_backlight
    current_backlight=$(get_pyui_config_value ".backlight" 5)
    local new_backlight=$((current_backlight + 1))
    set_backlight "$new_backlight"
}

# Decrease backlight
# Usage: backlight_down
backlight_down() {
    local current_backlight
    current_backlight=$(get_pyui_config_value ".backlight" 5)
    local new_backlight=$((current_backlight - 1))
    set_backlight "$new_backlight"
}


##########     DISPLAY AND COMMUNICATION     ##########

PYUI_PIPE=/tmp/pyui_pipe

start_pyui_message_writer(){
    freemma
    rm $PYUI_PIPE
    [ -p $PYUI_PIPE ] || mkfifo $PYUI_PIPE
    /mnt/SDCARD/App/PyUI/launch.sh -msgDisplayRealtime True < $PYUI_PIPE &
    exec 3> $PYUI_PIPE
}

stop_pyui_message_writer() {
    if [ -e /proc/$$/fd/3 ]; then
        echo "EXIT_APP" >&3
        exec 3>&-
    fi
    freemma
}

display_message(){
    echo $1 >&3
}

log_and_display_message(){
    log_message "$1"
    display_message "$1"
}

show() {
    /customer/app/sdldisplay "$1"
}

vibrate() {
    /mnt/SDCARD/sprig/scripts/vibrate.sh "$@" &
}

##########     OTHER STUFF     ##########

init_volume_backlight() {
    current_backlight=$(get_pyui_config_value ".backlight" 5)
    set_backlight "$current_backlight"
    current_volume=$(get_pyui_config_value ".vol" 10)
    set_volume "$current_volume"
    log_message "Backlight initialized to $current_backlight."
    log_message "Volume initialized to $current_volume."
}

BRIGHTNESS_FILE="/sys/devices/soc0/soc/1f003400.pwm/pwm/pwmchip0/pwm0/duty_cycle"
SCREEN_BLANK_FILE="/proc/mi_modules/fb/mi_fb0"
BUTTON_ENABLE_FILE="/sys/module/gpio_keys_polled/parameters/button_enable"
EMU_LIST="retroarch scummvm pico8_dyn drastic OpenBOR OpenBOR_mod OpenBOR_new ffplay MainUI"

get_battery_percentage() {
    axp_test 2>/dev/null | jq -r '.battery // empty'
}

enter_pseudo_sleep() {
    killall -q -SIGSTOP $(echo $EMU_LIST) 2>/dev/null
    cat "$BRIGHTNESS_FILE" > /tmp/saved_brightness 2>/dev/null  # backup current brightness
    echo "GUI_SHOW 0 off" > "$SCREEN_BLANK_FILE" 2>/dev/null    # blank the screen
    echo "0" > "$BRIGHTNESS_FILE" 2>/dev/null                   # set brightness to 0
    [ -e "$BUTTON_ENABLE_FILE" ] && echo "N" > "$BUTTON_ENABLE_FILE" 2>/dev/null # disable input
    touch /tmp/screen_blanked                                   # create flag file
    set_volume_raw "-60"                                        # set effective volume to 0
    KILL_WIFI="$(get_config_value '.menuOptions."Lid and Power Settings".disableWifiInSleep.selected' "False")"
    if [ "$KILL_WIFI" = "True" ]; then
        /mnt/SDCARD/sprig/scripts/network/kill_wifi.sh
    fi
    cpuclock 100                                                # slow cpu to a crawl
}

exit_pseudo_sleep() {
    cpuclock 1600                                               # wake up cpu speed
    killall -q -SIGCONT $(echo $EMU_LIST) 2>/dev/null
    echo "GUI_SHOW 0 on" > "$SCREEN_BLANK_FILE" 2>/dev/null     # unblank screen
    if [ -f /tmp/saved_brightness ]; then
        cat /tmp/saved_brightness > "$BRIGHTNESS_FILE" 2>/dev/null  # restore previous brightness
    else
        echo "50" > "$BRIGHTNESS_FILE" 2>/dev/null              # default if previous not found
    fi
    [ -e "$BUTTON_ENABLE_FILE" ] && echo "Y" > "$BUTTON_ENABLE_FILE" 2>/dev/null # re-enable input
    rm -f /tmp/screen_blanked /tmp/saved_brightness             # clean up temp files

    VOLUME="$(get_pyui_config_value '.vol' 5)"
    set_volume "$VOLUME"                                        # restore volume from settings

    WIFI_ENABLED="$(get_pyui_config_value '.wifi' 1)"
    if [ "$WIFI_ENABLED" -eq 1 ]; then
        /mnt/SDCARD/sprig/scripts/network/start_wifi.sh
        /mnt/SDCARD/sprig/scripts/network/start_stop_services.sh
    fi
    pgrep retroarch 2>/dev/null && /mnt/SDCARD/sprig/scripts/enforceSmartCPU.sh # return to smart mode
}


read_only_check() {
    log_message "Performing read-only check"
    MNT_LINE=$(mount | grep "SDCARD")
    if [ -n "$MNT_LINE" ]; then
        log_message "mount line for SD card: $MNT_LINE" -v
        MNT_STATUS=$(echo "$MNT_LINE" | cut -d'(' -f2 | cut -d',' -f1)
        if [ "$MNT_STATUS" = "ro" ] && [ -n /dev/mmcblk0p1 ]; then
            log_message "SD card is mounted as RO. Attempting to remount."
            mount -o remount,rw /dev/mmcblk0p1 /mnt/SDCARD
        else
            log_message "SD card is not read-only."
        fi
    fi
}


# Get sprig-specific settings from sprig-config.json
# example usage:
# ADB_ENABLED="$(get_config_value '.menuOptions."Network Settings".enableADB.selected' "True")"
get_config_value() {
    local key="$1"
    local default="$2"
    local file="/mnt/SDCARD/Saves/sprig/sprig-config.json"

    jq -r "${key} // \"$default\"" "$file"
}

get_pyui_config_value() {
    local key="$1"
    local default="$2"
    local file="/mnt/SDCARD/Saves/mini-flip-system.json"

    jq -r "${key} // \"$default\"" "$file"
}

set_pyui_config_value() {
    local key="$1"       # e.g. '.vol'
    local value="$2"     # e.g. '10'
    local file="/mnt/SDCARD/Saves/mini-flip-system.json"

    [ ! -f "$file" ] && echo '{}' > "$file"
    tmpfile="$(mktemp)"
    jq "$key = $value" "$file" > "$tmpfile" && mv "$tmpfile" "$file"
}

