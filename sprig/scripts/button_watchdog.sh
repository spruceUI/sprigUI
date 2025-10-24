#!/bin/sh

. /mnt/SDCARD/sprig/helperFunctions.sh

DEVICE="/dev/input/event0"
POWER_OFF_SCRIPT="/mnt/SDCARD/sprig/scripts/save_poweroff.sh"
GAMESWITCHER_SCRIPT="/mnt/SDCARD/sprig/scripts/gameswitcher.sh"
HOLD_MIN=1   # minimum seconds to trigger
HOLD_MAX=2   # maximum seconds to trigger

# Start evtest in background and read its output line-by-line
evtest "$DEVICE" 2>/dev/null | while read -r line; do
    case "$line" in
        *"code 116 (KEY_POWER), value 1"*)
            power_btn_press_time=$(date +%s)
            log_message "Power button pressed at $power_btn_press_time"
            ;;
        *"code 116 (KEY_POWER), value 0"*)
            if [ -n "$power_btn_press_time" ]; then
                release_time=$(date +%s)
                log_message "Power button released at $release_time"
                duration=$((release_time - power_btn_press_time))
                if [ "$duration" -ge "$HOLD_MIN" ] && [ "$duration" -le "$HOLD_MAX" ]; then
                    log_message "Power button held ${duration}s — running $POWER_OFF_SCRIPT"
                    "$POWER_OFF_SCRIPT" &
                else
                    log_message "Power button held ${duration}s — ignored (outside range ${HOLD_MIN}-${HOLD_MAX}s)"
                fi
                power_btn_press_time=""
            fi
            ;;
        *"code 1 (KEY_ESC), value 1"*)
            menu_btn_press_time=$(date +%s)
            log_message "Menu button pressed at $menu_btn_press_time"
            ;;
        *"code 1 (KEY_ESC), value 0"*)
            log_message "Menu button released at $menu_btn_press_time"
            if [ -n "$menu_btn_press_time" ]; then
                release_time=$(date +%s)
                log_message "Menu button released at $release_time"
                duration=$((release_time - menu_btn_press_time))
                if [ "$duration" -ge "$HOLD_MIN" ]; then
                    log_message "Menu button held ${duration}s — running $GAMESWITCHER_SCRIPT"
                    "$GAMESWITCHER_SCRIPT" &
                else
                    log_message "Menu button held ${duration}s — ignored (not held for at least ${HOLD_MIN})"
                fi
                menu_btn_press_time=""
            fi
            ;;
    esac
done &
