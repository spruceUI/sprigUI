#!/bin/sh

##### DEFINE BASE VARIABLES #####

. /mnt/SDCARD/sprig/helperFunctions.sh

set_performance

log_message "-----Launching Emulator-----"
log_message "trying: $0 $@"

EMU_NAME="$(echo "$1" | cut -d'/' -f5)"
EMU_DIR="/mnt/SDCARD/Emu/${EMU_NAME}"
EMU_JSON_PATH="${EMU_DIR}/config.json"
GAME="$(basename "$1")"
CORE="$(jq -r '.menuOptions.Emulator.selected' "$EMU_JSON_PATH")"

DISABLE_WIFI="$(get_config_value '.menuOptions."Network Settings".disableWifiInGame.selected' "False")"

##### GENERAL FUNCTIONS #####

get_core_override() {
	local core_override="$(jq -r --arg game "$GAME" '.menuOptions.Emulator.overrides[$game]' "$EMU_JSON_PATH")"
	if [ -n "$core_override" ] && [ "$core_override" != "null" ]; then
		export CORE=$core_override
	fi
}

use_default_emulator() {
	export CORE="$(jq -r '.default_emulator' "$EMU_JSON_PATH")"
	log_message "Using default core of $CORE to run $EMU_NAME"
}


set_cpu_mode() {
	if [ "$EMU_NAME" != "NDS" ] && [ "$EMU_NAME" != "PICO8" ]; then
		/mnt/SDCARD/sprig/scripts/enforceSmartCPU.sh &
	fi
}


##### EMULATOR LAUNCH FUNCTIONS #####

run_drastic() {

	# Keep saves and configs in a safe location
	for dirname in backup config savestates; do
		mkdir -p "/mnt/SDCARD/Emu/NDS/$dirname"
		mkdir -p "/mnt/SDCARD/Saves/NDS/$dirname"
		if ! mount | grep -q "/mnt/SDCARD/Emu/NDS/$dirname"; then
			mount --bind /mnt/SDCARD/Saves/NDS/$dirname /mnt/SDCARD/Emu/NDS/$dirname
		fi
	done

	mydir=/mnt/SDCARD/Emu/NDS
	export HOME=$mydir
	export PATH=$mydir:$PATH
	export LD_LIBRARY_PATH=$mydir/libs:$LD_LIBRARY_PATH
	export SDL_VIDEODRIVER=mmiyoo
	export SDL_AUDIODRIVER=mmiyoo
	export EGL_VIDEODRIVER=mmiyoo

	killall audioserver
	killall audioserver.mod

	sv=`cat /proc/sys/vm/swappiness`

	# 60 by default
	echo 10 > /proc/sys/vm/swappiness

	cd $mydir

	cpuclock 1600

	./drastic "$ROM_FILE"
	sync

	echo $sv > /proc/sys/vm/swappiness

	for dirname in backup config savestates; do
		umount /mnt/SDCARD/Emu/NDS/$dirname  >/dev/null 2>&1
	done
}

run_openbor() {
	fbset -g 640 480 640 960 32
	export HOME="$EMU_DIR"
	export PATH="$EMU_DIR:$PATH"
	export LD_LIBRARY_PATH="$EMU_DIR/lib:$LD_LIBRARY_PATH"
	export SDL_VIDEODRIVER=mmiyoo
	export SDL_AUDIODRIVER=mmiyoo

	killall audioserver
	killall audioserver.mod
	
	cd "$EMU_DIR"

	# Keep saves in a safe location
	if ! mount | grep -q "/mnt/SDCARD/Emu/OPENBOR/Saves"; then
		mkdir -p "/mnt/SDCARD/Emu/OPENBOR/Saves"
		mkdir -p "/mnt/SDCARD/Saves/OpenBOR"
		mount --bind /mnt/SDCARD/Saves/OpenBOR /mnt/SDCARD/Emu/OPENBOR/Saves
	fi

	mypak="$(basename "$ROM_FILE")"
	if [ "$mypak" = "Final Fight LNS.pak" ]; then
		./OpenBOR_mod "$ROM_FILE"
	else
		./OpenBOR_new "$ROM_FILE"
	fi
	sync
	fbset -g 752 560 752 1120 32
	umount /mnt/SDCARD/Emu/OPENBOR/Saves >/dev/null 2>&1
}

run_port() {
	/bin/sh "$ROM_FILE"
}

sync_pico8_volume() {
    SYSTEM_JSON="/appconfigs/system.json"
    PICO8_CONFIG="/mnt/SDCARD/Emu/PICO8/.lexaloffle/pico-8/config.txt"

    # Get volume (0–20) from system.json
    sysvol=$(jq -r '.vol' "$SYSTEM_JSON" 2>/dev/null)
    [ -z "$sysvol" ] && log_message "WARNING: Unable to sync Pico-8 with system volume level." && return 1

    # Convert 0–20 → 0–256 with rounding
    pico_vol=$(( (sysvol * 256 + 10) / 20 ))

    # Replace the line starting with "volume " in the Pico-8 config
    if grep -q '^volume ' "$PICO8_CONFIG"; then
        sed -i "s/^volume .*/volume ${pico_vol}/" "$PICO8_CONFIG"
    else
        echo "volume ${pico_vol}" >> "$PICO8_CONFIG"
    fi

    log_message "Pico-8 volume synced: system vol=$sysvol → pico vol=$pico_vol"
}

run_pico8() {

	export HOME="$EMU_DIR"
	export PATH="$HOME"/bin:$PATH:"/mnt/SDCARD/BIOS"
	export LD_LIBRARY_PATH="$HOME/lib:/mnt/SDCARD/sprig/lib:/mnt/SDCARD/App/PyUI/libs:$LD_LIBRARY_PATH"

	cd "$HOME"

	export SDL_VIDEODRIVER=mmiyoo
	export SDL_AUDIODRIVER=mmiyoo
	export EGL_VIDEODRIVER=mmiyoo
	export SDL_MMIYOO_DOUBLE_BUFFER=1

	killall audioserver
	killall audioserver.mod
	sync_pico8_volume
	cpuclock 1600
	if [ "${GAME##*.}" = "splore" ]; then
		pico8_dyn -preblit_scale 3 -pixel_perfect 0 -splore -root_path "/mnt/SDCARD/Roms/PICO8/"
	else
		pico8_dyn -preblit_scale 3 -pixel_perfect 0 -run "$ROM_FILE"
	fi
	sync
}

run_retroarch() {

	export RA_BIN="retroarch"
	RA_DIR="/mnt/SDCARD/RetroArch"
	cd "$RA_DIR"

	CORE_DIR="$RA_DIR/.retroarch/cores"

	if [ -f "$EMU_DIR/${CORE}_libretro.so" ]; then
		CORE_PATH="$EMU_DIR/${CORE}_libretro.so"
	else
		CORE_PATH="$CORE_DIR/${CORE}_libretro.so"
	fi

	HOME="$RA_DIR/" "$RA_DIR/$RA_BIN" -v --log-file /mnt/SDCARD/Saves/retroarch.log -L "$CORE_PATH" "$ROM_FILE"
}


 ########################
##### MAIN EXECUTION #####
 ########################

if [ -z "$CORE" ] || [ "$CORE" = "null" ]; then
	use_default_emulator
fi

get_core_override

set_cpu_mode

if [ "$DISABLE_WIFI" = "True" ]; then
	/mnt/SDCARD/sprig/scripts/kill_wifi.sh &
	log_message "Disabling Wi-Fi and network services while in game."
fi

# Sanitize the rom path
ROM_FILE="$(echo "$1" | sed 's|/media/SDCARD0/|/mnt/SDCARD/|g')"
export ROM_FILE="$(readlink -f "$ROM_FILE")"

case $EMU_NAME in
	"NDS")
		run_drastic
		;;
	"OPENBOR")
		run_openbor
		;;
	"PICO8")
		# load_pico8_control_profile
		run_pico8
		;;
	"PORTS")
		run_port
		;;
	*)
		run_retroarch
		;;
esac

kill -9 $(pgrep -f enforceSmartCPU.sh) 2>/dev/null

rm -f /tmp/cmd_to_run.sh # do this or else games will sometimes launch when you reload PyUI/change themes

log_message "-----Closing Emulator-----"
