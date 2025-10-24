#!/bin/sh

. /mnt/SDCARD/sprig/helperFunctions.sh

game_switcher_enabled="$(get_pyui_config_value '.gameSwitcherEnabled' "True")"

# If the key is missing or explicitly set to true, proceed
if [ -z "$game_switcher_enabled" ] || [ "$game_switcher_enabled" = "true" ]; then
	if pgrep "retroarch" >/dev/null; then
		do_vibrate="$(get_config_value '.menuOptions."Game Switcher Settings".menuShouldVibrate.selected' "True")"
		# Only vibrate if enabled
		if [ "$do_vibrate" = "True" ]; then
			vibrate 0.4
		fi
		touch /mnt/SDCARD/App/PyUI/pyui_gs_trigger
		killall -q -15 retroarch
	fi
fi
