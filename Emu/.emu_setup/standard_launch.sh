#!/bin/sh

##### DEFINE BASE VARIABLES #####

. /mnt/SDCARD/spruce/sprig/helperFunctions.sh

log_message "-----Launching Emulator-----" -v
log_message "trying: $0 $@" -v

export EMU_NAME="$(echo "$1" | cut -d'/' -f5)"
export GAME="$(basename "$1")"
export EMU_DIR="/mnt/SDCARD/Emu/${EMU_NAME}"
export DEF_DIR="/mnt/SDCARD/Emu/.emu_setup/defaults"
export OPT_DIR="/mnt/SDCARD/Emu/.emu_setup/options"
export OVR_DIR="/mnt/SDCARD/Emu/.emu_setup/overrides"
export DEF_FILE="$DEF_DIR/${EMU_NAME}.opt"
export OPT_FILE="$OPT_DIR/${EMU_NAME}.opt"
export OVR_FILE="$OVR_DIR/$EMU_NAME/$GAME.opt"
export CUSTOM_DEF_FILE="$EMU_DIR/default.opt"

##### GENERAL FUNCTIONS #####

import_launch_options() {
	if [ -f "$DEF_FILE" ]; then
		. "$DEF_FILE"
	elif [ -f "$CUSTOM_DEF_FILE" ]; then
		. "$CUSTOM_DEF_FILE"
	else
		log_message "WARNING: Default .opt file not found for $EMU_NAME!" -v
	fi

	if [ -f "$OPT_FILE" ]; then
		. "$OPT_FILE"
	else
		log_message "WARNING: System .opt file not found for $EMU_NAME!" -v
	fi

	if [ -f "$OVR_FILE" ]; then
		. "$OVR_FILE";
		log_message "Launch setting OVR_FILE detected @ $OVR_FILE" -v
	else
		log_message "No launch OVR_FILE detected. Using current system settings." -v
	fi
}

set_cpu_mode() {
	if [ "$MODE" != "overclock" ] && [ "$MODE" != "performance" ]; then
		/mnt/SDCARD/sprig/enforceSmartCPU.sh &
	fi
}


##### EMULATOR LAUNCH FUNCTIONS #####

	run_ffplay() {
	mydir=`dirname "$0"`
	export HOME=$mydir
	export PATH="$mydir:$PATH"
	export LD_LIBRARY_PATH="$mydir/libs:$LD_LIBRARY_PATH"

	cd $mydir
	ffplay -vf "hflip,vflip" -i "$1"
}

run_drastic() {
	CUST_LOGO=0
	CUST_CPUCLOCK=1
	USE_752x560_RES=0

	mydir=`dirname "$0"`

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

	if [ -f /mnt/SDCARD/.tmp_update/script/stop_audioserver.sh ]; then
		/mnt/SDCARD/.tmp_update/script/stop_audioserver.sh
	else
		killall audioserver
		killall audioserver.mod
	fi

	if [  -d "/customer/app/skin_large" ]; then
		USE_752x560_RES=1
	fi

	if [ "$USE_752x560_RES" == "1" ]; then
		fbset -g 752 560 752 1120 32
	fi

	cd $mydir
	if [ "$CUST_LOGO" == "1" ]; then
		./png2raw
	fi

	sv=`cat /proc/sys/vm/swappiness`

	# 60 by default
	echo 10 > /proc/sys/vm/swappiness

	cd $mydir

	if [ "$CUST_CPUCLOCK" == "1" ]; then
		./cpuclock 1600
	fi

	./drastic "$ROM_FILE"
	sync

	echo $sv > /proc/sys/vm/swappiness

	if [  -d "/customer/app/skin_large" ]; then
		USE_752x560_RES=0
	fi

	if [ "$USE_752x560_RES" == "1" ]; then
		fbset -g 640 480 640 960 32
	fi
}

run_openbor() {
	mydir=`dirname "$0"`
	mypak=`basename "$1"`
	fbset -g 640 480 640 960 32
	export HOME=$mydir
	export PATH=$mydir:$PATH
	export LD_LIBRARY_PATH=$mydir/lib:$LD_LIBRARY_PATH
	export SDL_VIDEODRIVER=mmiyoo
	export SDL_AUDIODRIVER=mmiyoo
	echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

	if [ -f /mnt/SDCARD/.tmp_update/script/stop_audioserver.sh ]; then
		/mnt/SDCARD/.tmp_update/script/stop_audioserver.sh
	else
		killall audioserver
		killall audioserver.mod
	fi
	
	cd $mydir
	if [ "$mypak" == "Final Fight LNS.pak" ]; then
		./OpenBOR_mod "$1"
	else
		./OpenBOR_new "$1"
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

	case "$PLATFORM" in
		"A30")
			if [ "$CONTROL_PROFILE" = "Steward" ]; then
				export LD_LIBRARY_PATH="$HOME"/lib-stew:$LD_LIBRARY_PATH
			else
				export LD_LIBRARY_PATH="$HOME"/lib-cine:$LD_LIBRARY_PATH
			fi
			;;
		"Flip")
			export LD_LIBRARY_PATH="$HOME"/lib-Flip:$LD_LIBRARY_PATH
			;;
		"Brick" | "SmartPro")
			export LD_LIBRARY_PATH="$HOME"/lib-trimui:$LD_LIBRARY_PATH
			;;
	esac

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

extract_game_dir(){
    # long-term come up with better method.
    # this is short term for testing
    gamedir_line=$(grep "^GAMEDIR=" "$ROM_FILE")
    # If gamedir_name ends with a slash, remove the slash
    gamedir_line="${gamedir_line%/}"
    # Extract everything after the last '/' in the GAMEDIR line and assign it to game_dir
    game_dir="/mnt/SDCARD/Roms/PORTS/${gamedir_line##*/}"
    # If game_dir ends with a quote, remove the quote
    echo "${game_dir%\"}"
}

is_retroarch_port() {
    # Check if the file contains "retroarch"
    if grep -q "retroarch" "$ROM_FILE"; then
        return 1;
    else
        return 0;
    fi
}

run_port() {
	if [ "$PLATFORM" = "Flip" ] || [ "$PLATFORM" = "Brick" ]; then

        is_retroarch_port
        if [[ $? -eq 1 ]]; then
            PORTS_DIR=/mnt/SDCARD/Roms/PORTS
            cd /mnt/SDCARD/RetroArch/
            export HOME="/mnt/SDCARD/Saves/flip/home"
            export LD_LIBRARY_PATH="/mnt/SDCARD/spruce/flip/lib/:/usr/lib:/mnt/SDCARD/spruce/flip/muOS/usr/lib/:/mnt/SDCARD/spruce/flip/muOS/lib/:/usr/lib32:/mnt/SDCARD/spruce/flip/lib32/:/mnt/SDCARD/spruce/flip/muOS/usr/lib32/:$LD_LIBRARY_PATH"
            export PATH="/mnt/SDCARD/spruce/flip/bin/:$PATH"
             "$ROM_FILE" &> /mnt/SDCARD/Saves/spruce/port.log
        else
            PORTS_DIR=/mnt/SDCARD/Roms/PORTS
            cd $PORTS_DIR
            export HOME="/mnt/SDCARD/Saves/flip/home"
            export LD_LIBRARY_PATH="/mnt/SDCARD/spruce/flip/lib/:/usr/lib:/mnt/SDCARD/spruce/flip/muOS/usr/lib/:/mnt/SDCARD/spruce/flip/muOS/lib/:/usr/lib32:/mnt/SDCARD/spruce/flip/lib32/:/mnt/SDCARD/spruce/flip/muOS/usr/lib32/:$LD_LIBRARY_PATH"
            export PATH="/mnt/SDCARD/spruce/flip/bin/:$PATH"
            "$ROM_FILE" &> /mnt/SDCARD/Saves/spruce/port.log
        fi
        
        /mnt/SDCARD/spruce/flip/unbind-new-libmali.sh
    else
        PORTS_DIR=/mnt/SDCARD/Roms/PORTS
        cd $PORTS_DIR
        /bin/sh "$ROM_FILE" 
    fi
}

run_retroarch() {

	if setting_get "expertRA"; then
		export RA_BIN="retroarch"
	else
		export RA_BIN="ra32.ss"
	fi

	RA_DIR="/mnt/SDCARD/RetroArch"
	cd "$RA_DIR"

	CORE_DIR="$RA_DIR/.retroarch/cores"

	if [ -f "$EMU_DIR/${CORE}_libretro.so" ]; then
		CORE_PATH="$EMU_DIR/${CORE}_libretro.so"
	else
		CORE_PATH="$CORE_DIR/${CORE}_libretro.so"
	fi

	#Swap below if debugging new cores
	#HOME="$RA_DIR/" "$RA_DIR/$RA_BIN" -v --log-file /mnt/SDCARD/Saves/retroarch.log -L "$CORE_PATH" "$ROM_FILE"
	HOME="$RA_DIR/" "$RA_DIR/$RA_BIN" -v -L "$CORE_PATH" "$ROM_FILE"
}


 ########################
##### MAIN EXECUTION #####
 ########################

import_launch_options
set_cpu_mode

flag_add 'emulator_launched'

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

auto_regen_tmp_update
