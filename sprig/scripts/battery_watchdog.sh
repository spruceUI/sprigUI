#!/bin/sh

. /mnt/SDCARD/sprig/scripts/helperFunctions.sh

BAT_LOG="/mnt/SDCARD/Saves/sprig/battery.log"
log_message "Battery watchdog started. Starting battery: $(get_battery_percentage)"

mkdir -p "$(dirname "$BAT_LOG")"        # Ensure log directory exists
: > "$BAT_LOG"                          # Reset log file safely

while true; do
    battery="$(get_battery_percentage)"
    if [ -n "$battery" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') $battery" >> "$BAT_LOG"
        if [ "$battery" -lt 2 ]; then
            /mnt/SDCARD/sprig/scripts/save_poweroff.sh
        fi
    else
        log_message "Battery watchdog: failed to read battery"
    fi
    sleep 30
done