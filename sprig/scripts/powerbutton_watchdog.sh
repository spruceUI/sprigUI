#!/bin/sh

. /mnt/SDCARD/sprig/helperFunctions.sh

DEVICE="/dev/input/event0"
TARGET_SCRIPT="/mnt/SDARD/save_poweroff.sh"
HOLD_TIME=2  # seconds

# Start evtest in background and read its output line-by-line
evtest "$DEVICE" 2>/dev/null | while read -r line; do
    # Look for power key press/release events
    case "$line" in
        *"code 116 (KEY_POWER), value 1"*)
            press_time=$(date +%s)
            log_message "Power button pressed at $press_time"
            ;;
        *"code 116 (KEY_POWER), value 0"*)
            if [ -n "$press_time" ]; then
                release_time=$(date +%s)
                log_message "power button released at $release_time"
                duration=$((release_time - press_time))
                if [ "$duration" -ge "$HOLD_TIME" ]; then
                    log_message "Power button held ${duration}s — running $TARGET_SCRIPT"
                    "$TARGET_SCRIPT" &
                fi
                press_time=""
            fi
            ;;
    esac
done &