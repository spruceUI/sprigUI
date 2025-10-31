#!/bin/sh

. /mnt/SDCARD/sprig/helperFunctions.sh

game_switcher_enabled="$(get_pyui_config_value '.gameSwitcherEnabled' "True")"

# If the key is missing or explicitly set to true, proceed
if [ -z "$game_switcher_enabled" ] || [ "$game_switcher_enabled" = "true" ]; then
	if pgrep "retroarch" >/dev/null || pgrep "pico8_dyn" >/dev/null || pgrep "drastic" >/dev/null; then
		do_vibrate="$(get_config_value '.menuOptions."Game Switcher Settings".menuShouldVibrate.selected' "True")"
		# Only vibrate if enabled
		if [ "$do_vibrate" = "True" ]; then
			vibrate 0.4
		fi
		touch /mnt/SDCARD/App/PyUI/pyui_gs_trigger
	    log_message "Create gs trigger file, closing retroarch, pico8_dyn, drastic"
		killall -q -15 retroarch
		killall -q -15 pico8_dyn
		killall -q -15 drastic
	else
	    log_message "retroarch, pico8_dyn, nor drastic were running"
	fi
else
    log_message "GameSwitcher not enabled"
fi
