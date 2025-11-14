#!/bin/sh

. /mnt/SDCARD/sprig/scripts/helperFunctions.sh

DEVICE="/dev/input/event0"
POWER_OFF_SCRIPT="/mnt/SDCARD/sprig/scripts/save_poweroff.sh"
GAMESWITCHER_SCRIPT="/mnt/SDCARD/sprig/scripts/gameswitcher.sh"
HOLD_MIN=1   # minimum seconds to trigger
HOLD_MAX=2   # maximum seconds to trigger
BRIGHTNESS_FILE="/sys/devices/soc0/soc/1f003400.pwm/pwm/pwmchip0/pwm0/duty_cycle"
SCREEN_BLANK_FILE="/proc/mi_modules/fb/mi_fb0"
BUTTON_ENABLE_FILE="/sys/module/gpio_keys_polled/parameters/button_enable"

reset_poweroff_timer() {
    [ -n "$POWER_PID" ] && kill -9 "$POWER_PID"
    start_poweroff_timer &
    export POWER_PID=$!
}


start_poweroff_timer() {
    POWEROFF_TIME="$(get_config_value '.menuOptions."Lid and Power Settings".idlePowerdownTimer.selected' "Off")"
    case "$POWEROFF_TIME" in
        "Off") return 0 ;;
        "15m") sleep 900; "$POWER_OFF_SCRIPT" ;;
        "30m") sleep 1800; "$POWER_OFF_SCRIPT" ;;
        "1h") sleep 3600; "$POWER_OFF_SCRIPT" ;;
        "2h") sleep 7200; "$POWER_OFF_SCRIPT" ;;
    esac
}

init_volume_backlight
log_message "Button watchdog started."

# Wait until input is ready
for i in $(seq 1 25); do
    [ -e "$DEVICE" ] && break
    sleep 0.2
done

# Pre-export GPIO
if [ ! -d /sys/class/gpio/gpio48 ]; then
    echo 48 > /sys/class/gpio/export 2>/dev/null
fi

# start timer even before any buttons pressed
reset_poweroff_timer

# Start evtest in background and read its output line-by-line
evtest "$DEVICE" 2>/dev/null | while read -r line; do

    reset_poweroff_timer

    case "$line" in

        *"code 116 (KEY_POWER), value 1"*)
            # Check if screen is blanked - if so, wake it up immediately
            if [ -f /tmp/screen_blanked ]; then
                log_message "Power button pressed while screen blanked — restoring screen"
                exit_pseudo_sleep
                continue
            fi
            
            power_btn_press_time=$(date +%s)
            log_message "Power button pressed at $power_btn_press_time" -v
            touch /tmp/pwrbtn
            (
                sleep "$HOLD_MIN"
                if [ -f /tmp/pwrbtn ]; then
                    vibrate 0.03 3  # short triple after 1s
                    sleep $((3 - HOLD_MIN))
                    if [ -f /tmp/pwrbtn ]; then
                        vibrate 0.1 2   # longer double after 3s
                        sleep 0.1
                        [ -f /tmp/cmd_to_run.sh ] && /customer/kill_apps.sh
                    fi
                fi
            ) &
            ;;

        *"code 116 (KEY_POWER), value 0"*)
            if [ -n "$power_btn_press_time" ]; then
                release_time=$(date +%s)
                log_message "Power button released at $release_time" -v
                duration=$((release_time - power_btn_press_time))
                if [ "$duration" -ge "$HOLD_MIN" ] && [ "$duration" -le "$HOLD_MAX" ]; then
                    log_message "Power button held ${duration}s — running $POWER_OFF_SCRIPT"
                    "$POWER_OFF_SCRIPT" &
                elif [ "$duration" -lt "$HOLD_MIN" ]; then
                    log_message "Power button tapped (${duration}s) — blanking screen"
                    enter_pseudo_sleep &
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
                log_message "Menu button pressed at $menu_btn_press_time" -v
                touch /tmp/menubtn

                # Launch background timer that waits required seconds, then triggers the action
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

                if pgrep "retroarch" >/dev/null; then
                    log_message "Triggering RA in game menu"
                    send_event 42:1 97:1
                    sleep 0.2
                    send_event 42:0 97:0
                fi
            fi
            ;;
            
        *"code 1 (KEY_ESC), value 0"*)
            log_message "Menu button released at $(date +%s)" -v
            rm -f /tmp/menubtn
            # Kill background hold timer if still running
            if [ -n "$menu_hold_pid" ]; then
                kill "$menu_hold_pid" 2>/dev/null
                wait "$menu_hold_pid" 2>/dev/null
                menu_hold_pid=""
            fi
            ;;

        *"code 97 (KEY_RIGHTCTRL), value 1"*)
            touch /tmp/select_pressed
            ;;
        *"code 97 (KEY_RIGHTCTRL), value 0"*)
            rm -f /tmp/select_pressed
            ;;

        *"code 115 (KEY_VOLUMEUP), value 1"*)
            log_message "Volume Up button pressed" -v
            if [ -e /tmp/select_pressed ]; then
                backlight_up
            else
                volume_up
            fi
            ;;

        *"code 114 (KEY_VOLUMEDOWN), value 1"*)
            log_message "Volume Down button pressed" -v
            if [ -e /tmp/select_pressed ]; then
                backlight_down
            else
                volume_down
            fi
            ;;
    esac

done &
