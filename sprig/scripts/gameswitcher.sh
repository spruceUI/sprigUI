#!/bin/sh

JSON_FILE="/mnt/SDCARD/Saves/mini-flip-system.json"
KEY="gameSwitcherEnabled"

# Get the value of game_switcher_enabled (empty if missing)
value=$(grep -o "\"$KEY\"[[:space:]]*:[[:space:]]*[^,}]*" "$JSON_FILE" 2>/dev/null | head -n 1 | cut -d':' -f2 | tr -d '[:space:]"')

# If the key is missing or explicitly set to true, proceed
if [ -z "$value" ] || [ "$value" = "true" ]; then
	if pgrep "retroarch" >/dev/null; then
		/mnt/SDCARD/sprig/scripts/vibrate.sh 0.4
		touch /mnt/SDCARD/App/PyUI/pyui_gs_trigger
		killall -q -15 retroarch
	fi
fi
