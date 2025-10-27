#!/bin/sh

##### DEFINE BASE VARIABLES #####

. /mnt/SDCARD/sprig/helperFunctions.sh

set_performance

log_message "-----Launching Emulator-----"
log_message "trying: $0 $@"

export EMU_NAME="$(echo "$1" | cut -d'/' -f5)"
export EMU_DIR="/mnt/SDCARD/Emu/${EMU_NAME}"
export EMU_JSON_PATH="${EMU_DIR}/config.json"
export GAME="$(basename "$1")"
export CORE="$(jq -r '.menuOptions.Emulator.selected' "$EMU_JSON_PATH")"

##### GENERAL FUNCTIONS #####

get_core_override() {
	local core_override="$(jq -r --arg game "$GAME" '.menuOptions.Emulator.overrides[$game]' "$EMU_JSON_PATH")"
	if [ -n "$core_override" ] && [ "$core_override" != "null" ]; then
		export CORE=$core_override
	fi
}

use_default_emulator() {

	case "$EMU_NAME" in
		"AMIGA")			default_core="uae4arm";;
		"ARCADE"|"NEOGEO")	default_core="fbneo";;
		"ARDUBOY")			default_core="ardens";;
		"ATARI")			default_core="stella2014";;
		"ATARIST")			default_core="hatari";;
		"CHAI")				default_core="chailove";;
		"COLECO"|"MSX")		default_core="bluemsx";;
		"COMMODORE")		default_core="vice_x64";;
		"CPC")				default_core="cap32";;
		"DOOM")				default_core="prboom";;
		"DOS")				default_core="dosbox_pure";;
		"EASYRPG")			default_core="easyrpg";;
		"EIGHTHUNDRED")		default_core="atari800";;
		"FAIRCHILD")		default_core="freechaf";;
		"FAKE08")			default_core="fake08";;
		"FC"|"FDS")			default_core="fceumm";;
		"FIFTYTWOHUNDRED")	default_core="a5200";;
		"GAMETANK")			default_core="gametank";;
		"GB"|"GBC")			default_core="gambatte";;
		"GBA"|"SGB")		default_core="mgba";;
		"GG"|"MS"|"MSUMD"|"SEGASGONE")	default_core="genesis_plus_gx";;
		"GW")				default_core="gw";;
		"INTELLIVISION")	default_core="freeintv";;
		"LYNX")				default_core="handy";;
		"MD"|"SEGACD"|"THIRTYTWOX")	default_core="picodrive";;
		"MEGADUCK")			default_core="sameduck";;
		"MSU1"|"SFC")		default_core="snes9x";;
		"NEOCD")			default_core="neocd";;
		"NGP"|"NGPC")		default_core="mednafen_ngp";;
		"ODYSSEY")			default_core="o2em";;
		"PCE"|"PCECD")		default_core="mednafen_pce_fast";;
		"POKE")				default_core="pokemini";;
		"PS")				default_core="pcsx_rearmed";;
		"QUAKE")			default_core="tyrquake";;
		"SEVENTYEIGHTHUNDRED")	default_core="prosystem";;
		"SGFX")				default_core="mednafen_supergrafx";;
		"SUPERVISION")		default_core="potator";;
		"TIC")				default_core="tic80";;
		"VB")				default_core="mednafen_vb";;
		"VECTREX")			default_core="vecx";;
		"VIC20")			default_core="vice_xvic";;
		"WOLF")				default_core="ecwolf";;
		"WS"|"WSC")			default_core="mednafen_wswan";;
		"X68000")			default_core="px68k";;
		"ZXS")				default_core="fuse";;
		*)					default_core="";;
	esac

	export CORE="$default_core"
	log_message "Using default core of $CORE to run $EMU_NAME"
}


set_cpu_mode() {
	if [ "$EMU_NAME" != "NDS" ] && [ "$EMU_NAME" != "PICO8" ]; then
		/mnt/SDCARD/sprig/scripts/enforceSmartCPU.sh &
	fi
}


##### EMULATOR LAUNCH FUNCTIONS #####

run_ffplay() {
	mydir="/mnt/SDCARD/Emu/MEDIA"
	export HOME="$mydir"
	export PATH="$mydir:$PATH"
	export LD_LIBRARY_PATH="$mydir/libs:$LD_LIBRARY_PATH"

	cd $mydir
	ffplay -vf "hflip,vflip" -i "$ROM_FILE"
}

run_drastic() {

	mydir=/mnt/SDCARD/Emu/NDS
	cd $mydir
	if [ ! -f "/tmp/.show_hotkeys" ]; then
		touch /tmp/.show_hotkeys
		LD_LIBRARY_PATH=./libs:/customer/lib:/config/lib ./show_hotkeys
	fi

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

	./cpuclock 1600

	./drastic "$ROM_FILE"
	sync

	echo $sv > /proc/sys/vm/swappiness
}

run_openbor() {
	mydir=/mnt/SDCARD/Emu/OPENBOR
	mypak=`basename "$ROM_FILE"`
	fbset -g 640 480 640 960 32
	export HOME=$mydir
	export PATH=$mydir:$PATH
	export LD_LIBRARY_PATH=$mydir/lib:$LD_LIBRARY_PATH
	export SDL_VIDEODRIVER=mmiyoo
	export SDL_AUDIODRIVER=mmiyoo

	killall audioserver
	killall audioserver.mod
	
	cd $mydir
	if [ "$mypak" == "Final Fight LNS.pak" ]; then
		./OpenBOR_mod "$ROM_FILE"
	else
		./OpenBOR_new "$ROM_FILE"
	fi
	sync
	fbset -g 752 560 752 1120 32
}

run_port() {
	/bin/sh "$ROM_FILE"
}

get_curvol() {
    awk '/LineOut/ {if (!printed) {gsub(",", "", $8); print $8; printed=1}}' /proc/mi_modules/mi_ao/mi_ao0
}

get_curmute() {
    awk '/LineOut/ {if (!printed) {gsub(",", "", $8); print $6; printed=1}}' /proc/mi_modules/mi_ao/mi_ao0
}

set_snd_level() {
    local target_vol="$1"
    local target_mute="$2"
    local current_vol
    local current_mute
    local start_time
    local elapsed_time

    start_time=$(date +%s)
    while [ ! -e /proc/mi_modules/mi_ao/mi_ao0 ]; do
        sleep 0.2
        elapsed_time=$(( $(date +%s) - start_time ))
        if [ "$elapsed_time" -ge 30 ]; then
            echo "Timed out waiting for /proc/mi_modules/mi_ao/mi_ao0"
            return 1
        fi
    done

    start_time=$(date +%s)
    while true; do
        echo "set_ao_volume 0 ${target_vol}dB" > /proc/mi_modules/mi_ao/mi_ao0
        echo "set_ao_volume 1 ${target_vol}dB" > /proc/mi_modules/mi_ao/mi_ao0
        echo "set_ao_mute ${target_mute}" > /proc/mi_modules/mi_ao/mi_ao0

        current_vol=$(get_curvol)
        current_mute=$(get_curmute)

        if [ "$current_vol" = "$target_vol" ] && [ "$current_mute" = "$target_mute" ]; then
            echo "Volume set to ${current_vol}dB, Mute status: ${current_mute}"
            return 0
        fi

        elapsed_time=$(( $(date +%s) - start_time ))
        if [ "$elapsed_time" -ge 360 ]; then
            echo "Timed out trying to set volume and mute status"
            return 1
        fi

        sleep 0.2
    done
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
    curvol="$(get_curvol)"
    curmute="$(get_curmute)"
	set_snd_level "${curvol}" "${curmute}" &

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

# Sanitize the rom path
ROM_FILE="$(echo "$1" | sed 's|/media/SDCARD0/|/mnt/SDCARD/|g')"
export ROM_FILE="$(readlink -f "$ROM_FILE")"

case $EMU_NAME in
	"MEDIA")
		run_ffplay
		;;
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

kill -9 $(pgrep -f enforceSmartCPU.sh)

rm -f /tmp/cmd_to_run.sh # do this or else games will sometimes launch when you reload PyUI/change themes

log_message "-----Closing Emulator-----" -v
