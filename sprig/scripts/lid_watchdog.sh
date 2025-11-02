#!/bin/sh

. /mnt/SDCARD/sprig/helperFunctions.sh

LID_HALL_FILE="/sys/devices/soc0/soc/soc:hall-mh248/hallvalue"
POWER_OFF_SCRIPT="/mnt/SDCARD/sprig/scripts/save_poweroff.sh"
IDLE_TIMEOUT=5  # seconds to wait in sleep before full poweroff

# Wait until hall sensor is ready
for i in $(seq 1 25); do
    [ -e "$LID_HALL_FILE" ] && break
    sleep 0.2
done

if [ ! -e "$LID_HALL_FILE" ]; then
    log_message "Hall sensor file not found at $LID_HALL_FILE, lid watchdog disabled"
    exit 1
fi

log_message "Lid watchdog started, monitoring $LID_HALL_FILE"

# Read initial lid state
prev_state=$(cat "$LID_HALL_FILE" 2>/dev/null | head -c 1)

while true; do
    # Read current lid state (1 = open, 0 = closed)
    current_state=$(cat "$LID_HALL_FILE" 2>/dev/null | head -c 1)
    
    # Detect lid close event (transition from 1 to 0)
    if [ "$prev_state" = "1" ] && [ "$current_state" = "0" ]; then
        log_message "Lid closed detected, entering sleep mode"
        
        # Enter sleep immediately
        echo deep > /sys/power/mem_sleep 2>/dev/null
        echo mem > /sys/power/state 2>/dev/null
        
        log_message "Woke from sleep, checking if lid is still closed"
        
        # Start countdown - if lid stays closed for IDLE_TIMEOUT, poweroff
        elapsed=0
        while [ "$elapsed" -lt "$IDLE_TIMEOUT" ]; do
            current_state=$(cat "$LID_HALL_FILE" 2>/dev/null | head -c 1)
            
            # If lid opened, break out
            if [ "$current_state" = "1" ]; then
                log_message "Lid opened, cancelling poweroff"
                break
            fi
            
            sleep 1
            elapsed=$((elapsed + 1))
        done
        
        # If we reached the timeout with lid still closed, poweroff
        current_state=$(cat "$LID_HALL_FILE" 2>/dev/null | head -c 1)
        if [ "$current_state" = "0" ] && [ "$elapsed" -ge "$IDLE_TIMEOUT" ]; then
            log_message "Lid closed for ${IDLE_TIMEOUT}s, triggering poweroff"
            "$POWER_OFF_SCRIPT" &
        fi
    fi
    
    prev_state="$current_state"
    sleep 0.5
done
