#!/bin/sh

. /mnt/SDCARD/sprig/helperFunctions.sh

DEVICE="/dev/input/event0"
POWER_OFF_SCRIPT="/mnt/SDCARD/sprig/scripts/save_poweroff.sh"
GAMESWITCHER_SCRIPT="/mnt/SDCARD/sprig/scripts/gameswitcher.sh"
HOLD_MIN=1   # minimum seconds to trigger
HOLD_MAX=2   # maximum seconds to trigger

# Wait until input is ready
log_message "Waiting for $DEVICE..."
for i in $(seq 1 25); do
    [ -e "$DEVICE" ] && break
    sleep 0.2
done

# Pre-export GPIO
if [ ! -d /sys/class/gpio/gpio48 ]; then
    echo 48 > /sys/class/gpio/export 2>/dev/null
fi

vibe_timer() {
    sleep "$HOLD_MIN"

    if [ "$1" = "pwrbtn" ] && [ -f /tmp/pwrbtn ]; then
        vibrate 0.1
    elif [ "$1" = "menubtn" ] && [ -f /tmp/menubtn ]; then
        vibrate 0.01 5
    fi
}

# Start evtest in background and read its output line-by-line
evtest "$DEVICE" 2>/dev/null | while read -r line; do
    case "$line" in
        *"code 116 (KEY_POWER), value 1"*)
            power_btn_press_time=$(date +%s)
            log_message "Power button pressed at $power_btn_press_time"
            touch /tmp/pwrbtn
            vibe_timer "pwrbtn" &
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
                rm -f /tmp/pwrbtn
            fi
            ;;
        *"code 1 (KEY_ESC), value 1"*)
            menu_btn_press_time=$(date +%s)
            log_message "Menu button pressed at $menu_btn_press_time"
            touch  /tmp/menubtn
            vibe_timer "menubtn" &
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
                rm -f /tmp/menubtn
            fi
            ;;
    esac
done &
