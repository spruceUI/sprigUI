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
	if [ "$EMU_NAME" != "NDS" ]; then
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

run_pico8() {

	export HOME="$EMU_DIR"
	export PATH=$WGET_PATH"$HOME"/bin:$PATH:"/mnt/SDCARD/BIOS"

	if setting_get "pico8_stretch"; then
		case "$PLATFORM" in
			"A30") SCALING="-draw_rect 0,0,$DISPLAY_HEIGHT,$DISPLAY_WIDTH" ;; # handle A30's rotated screen
			*) SCALING="-draw_rect 0,0,$DISPLAY_WIDTH,$DISPLAY_HEIGHT" ;;
		esac
	else
		SCALING=""
	fi

	cd "$HOME"

	if [ "$PLATFORM" = "A30" ]; then
		export SDL_VIDEODRIVER=mali
		export SDL_JOYSTICKDRIVER=a30
		PICO8_BINARY="pico8_dyn"
		sed -i 's|^transform_screen 0$|transform_screen 135|' "$HOME/.lexaloffle/pico-8/config.txt"
	else
		PICO8_BINARY="pico8_64"
		sed -i 's|^transform_screen 135$|transform_screen 0|' "$HOME/.lexaloffle/pico-8/config.txt"
	fi

	if [ "${GAME##*.}" = "splore" ]; then
		check_and_connect_wifi
		$PICO8_BINARY -splore -width $DISPLAY_WIDTH -height $DISPLAY_HEIGHT -root_path "/mnt/SDCARD/Roms/PICO8/" $SCALING
	else
		$PICO8_BINARY -width $DISPLAY_WIDTH -height $DISPLAY_HEIGHT -scancodes -run "$ROM_FILE" $SCALING
	fi
	sync
}

load_pico8_control_profile() {
	HOME="$EMU_DIR"
	P8_DIR="/mnt/SDCARD/Emu/PICO8/.lexaloffle/pico-8"
	CONTROL_PROFILE="$(setting_get "pico8_control_profile")"

	case "$CONTROL_PROFILE" in
		"Doubled") 
			cp -f "$P8_DIR/sdl_controllers.facebuttons" "$P8_DIR/sdl_controllers.txt"
			;;
		"One-handed")
			cp -f "$P8_DIR/sdl_controllers.onehand" "$P8_DIR/sdl_controllers.txt"
			;;
		"Racing")
			cp -f "$P8_DIR/sdl_controllers.racing" "$P8_DIR/sdl_controllers.txt"
			;;
		"Doubled 2") 
			cp -f "$P8_DIR/sdl_controllers.facebuttons_reverse" "$P8_DIR/sdl_controllers.txt"
			;;
		"One-handed 2")
			cp -f "$P8_DIR/sdl_controllers.onehand_reverse" "$P8_DIR/sdl_controllers.txt"
			;;
		"Racing 2")
			cp -f "$P8_DIR/sdl_controllers.racing_reverse" "$P8_DIR/sdl_controllers.txt"
			;;
	esac
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
		load_pico8_control_profile
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
log_message "-----Closing Emulator-----" -v
