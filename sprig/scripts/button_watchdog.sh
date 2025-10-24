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

trigger_vibrate() {
    sleep "$HOLD_MIN"

    if [ "$1" = "pwrbtn" ] && [ -f /tmp/pwrbtn ]; then
        vibrate 0.1
    fi
}

# Start evtest in background and read its output line-by-line
evtest "$DEVICE" 2>/dev/null | while read -r line; do
    case "$line" in
        *"code 116 (KEY_POWER), value 1"*)
            power_btn_press_time=$(date +%s)
            log_message "Power button pressed at $power_btn_press_time"
            touch /tmp/pwrbtn
            trigger_vibrate "pwrbtn" &
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
            if [ -z "$menu_hold_pid" ]; then
                menu_btn_press_time=$(date +%s)
                log_message "Menu button pressed at $menu_btn_press_time"
                touch /tmp/menubtn

                # Launch background timer that waits HOLD_MIN seconds, then triggers the action
                (
                    menu_hold_time=$(get_config_value '.menuOptions."Game Switcher Settings".menuHoldTime.selected' 2)
                    sleep "$menu_hold_time"
                    # Check if the menubtn file still exists (i.e., not released)
                    if [ -f /tmp/menubtn ]; then
                        log_message "Menu button held for $HOLD_MIN seconds — running $GAMESWITCHER_SCRIPT"
                        "$GAMESWITCHER_SCRIPT" &
                    fi
                ) &
                menu_hold_pid=$!
            fi
            ;;
        *"code 1 (KEY_ESC), value 0"*)
            log_message "Menu button released at $(date +%s)"
            rm -f /tmp/menubtn
            # Kill background hold timer if still running
            if [ -n "$menu_hold_pid" ]; then
                kill "$menu_hold_pid" 2>/dev/null
                wait "$menu_hold_pid" 2>/dev/null
                menu_hold_pid=""
            fi
            ;;
    esac
done &
