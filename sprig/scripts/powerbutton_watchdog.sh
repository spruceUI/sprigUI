#!/bin/sh

. /mnt/SDCARD/sprig/helperFunctions.sh

DEVICE="/dev/input/event0"
TARGET_SCRIPT="/mnt/SDCARD/sprig/scripts/save_poweroff.sh"
HOLD_MIN=1   # minimum seconds to trigger
HOLD_MAX=2   # maximum seconds to trigger

# Start evtest in background and read its output line-by-line
evtest "$DEVICE" 2>/dev/null | while read -r line; do
    case "$line" in
        *"code 116 (KEY_POWER), value 1"*)
            press_time=$(date +%s)
            log_message "Power button pressed at $press_time"
            ;;
        *"code 116 (KEY_POWER), value 0"*)
            if [ -n "$press_time" ]; then
                release_time=$(date +%s)
                log_message "Power button released at $release_time"
                duration=$((release_time - press_time))
                if [ "$duration" -ge "$HOLD_MIN" ] && [ "$duration" -le "$HOLD_MAX" ]; then
                    log_message "Power button held ${duration}s — running $TARGET_SCRIPT"
                    "$TARGET_SCRIPT" &
                else
                    log_message "Power button held ${duration}s — ignored (outside range ${HOLD_MIN}-${HOLD_MAX}s)"
                fi
                press_time=""
            fi
            ;;
    esac
done &
