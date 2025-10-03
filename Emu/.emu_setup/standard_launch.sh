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
	if [ "$MODE" = "overclock" ]; then
		if [ "$EMU_NAME" = "NDS" ]; then
			( sleep 33 && set_overclock ) &
		else
			set_overclock
		fi
	fi

	if [ "$MODE" != "overclock" ] && [ "$MODE" != "performance" ]; then
		/mnt/SDCARD/spruce/scripts/enforceSmartCPU.sh &
	fi
}


##### EMULATOR LAUNCH FUNCTIONS #####

run_ffplay() {
	export HOME=$EMU_DIR
	cd $EMU_DIR
	if [ "$PLATFORM" = "A30" ]; then
		export PATH="$EMU_DIR"/bin:"$PATH"
		export LD_LIBRARY_PATH="$EMU_DIR"/libs:/usr/miyoo/lib:/usr/lib:"$LD_LIBRARY_PATH"
		ffplay -vf transpose=2 -fs -i "$ROM_FILE" > ffplay.log 2>&1
	else
		export PATH="$EMU_DIR"/bin64:"$PATH"
		export LD_LIBRARY_PATH="$LD_LIBRARY_PATH":"$EMU_DIR"/lib64
		/mnt/SDCARD/spruce/bin64/gptokeyb -k "ffplay" -c "./bin64/ffplay.gptk" &
		sleep 1
		ffplay -x $DISPLAY_WIDTH -y $DISPLAY_HEIGHT -fs -i "$ROM_FILE" > ffplay.log 2>&1 # trimui devices crash after about 30 seconds when not outputting to a log???
		kill -9 "$(pidof gptokeyb)"
	fi
}

function kill_runner() {
    PID=`pidof runner`
    if [ "$PID" != "" ]; then
        kill -9 $PID
    fi
}

run_drastic() {
	export HOME=$EMU_DIR
	cd $EMU_DIR

	if [ "$PLATFORM" = "A30" ]; then # only Steward is available; core switching does nothing

		[ -d "$EMU_DIR/backup-32" ] && mv "$EMU_DIR/backup-32" "$EMU_DIR/backup"
		# the SDL library is hard coded to open ttyS0 for joystick raw input 
		# so we pause joystickinput and create soft link to serial port
		killall -q -STOP joystickinput
		ln -s /dev/ttyS2 /dev/ttyS0

		cd $EMU_DIR
		if [ ! -f "/tmp/.show_hotkeys" ]; then
			touch /tmp/.show_hotkeys
			LD_LIBRARY_PATH=libs2:/usr/miyoo/lib ./show_hotkeys
		fi
		
		export LD_LIBRARY_PATH=libs:/usr/miyoo/lib:/usr/lib
		export SDL_VIDEODRIVER=mmiyoo
		export SDL_AUDIODRIVER=mmiyoo
		export EGL_VIDEODRIVER=mmiyoo

		if [ -f 'libs/libEGL.so' ]; then
			rm -rf libs/libEGL.so
			rm -rf libs/libGLESv1_CM.so
			rm -rf libs/libGLESv2.so
		fi
		./drastic32 "$ROM_FILE"
		# remove soft link and resume joystickinput
		rm /dev/ttyS0
		killall -q -CONT joystickinput
		[ -d "$EMU_DIR/backup" ] && mv "$EMU_DIR/backup" "$EMU_DIR/backup-32"

	else # 64-bit platform

		[ -d "$EMU_DIR/backup-64" ] && mv "$EMU_DIR/backup-64" "$EMU_DIR/backup"
		export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/lib64
		
		if [ "$PLATFORM" = "Brick" ]; then
			if [ "$CORE" = "drastic_steward" ]; then
				kill_runner
				LD_LIBRARY_PATH=/usr/trimui/lib ./runner&
				sleep 1
				export SDL_VIDEODRIVER=NDS
				./lib32_Brick/ld-linux-armhf.so.3 --library-path lib32_Brick ./drastic32 "$ROM_FILE" > /mnt/SDCARD/Saves/spruce/drastic-steward-brick.log 2>&1
				sync
				kill_runner
			else 

				##### TODO: HOOK UP TRNGAJE's DRASTIC FOR BRICK

				./drastic64 "$ROM_FILE" > /mnt/SDCARD/Saves/spruce/drastic-og-brick.log 2>&1
			fi

		elif [ "$PLATFORM" = "SmartPro" ]; then

			##### TODO: HOOK UP CORE SWITCH B/T TRNGAJE AND OG DRASTIC on SMART PRO; no Steward available

			export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$HOME/lib64_a133p"
			export SDL_AUDIODRIVER=dsp
			./drastic64 "$ROM_FILE" > /mnt/SDCARD/Saves/spruce/drastic-og-smartpro.log 2>&1

		elif [ "$PLATFORM" = "Flip" ]; then

			if [ -d /usr/l32 ] && [ "$CORE" = "drastic_steward" ]; then
				export SDL_VIDEODRIVER=NDS
				export LD_LIBRARY_PATH="$HOME/lib32_Flip:/usr/lib32:$LD_LIBRARY_PATH"
				./drastic32 "$ROM_FILE" > /mnt/SDCARD/Saves/spruce/drastic-steward-flip.log 2>&1

			elif [ "$CORE" = "drastic_trngaje" ]; then
				export LD_LIBRARY_PATH="$HOME/lib64_Flip:$LD_LIBRARY_PATH"
				mv ./drastic64 ./drastic
				./drastic "$ROM_FILE" > /mnt/SDCARD/Saves/spruce/drastic-trngaje-flip.log 2>&1
				mv ./drastic ./drastic64
			else
				# if overlay mount of /usr fails, fall back to original DraStic instead of Steward's
				./drastic64 "$ROM_FILE" > /mnt/SDCARD/Saves/spruce/drastic-og-flip.log
			fi
		fi
		
		[ -d "$EMU_DIR/backup" ] && mv "$EMU_DIR/backup" "$EMU_DIR/backup-64"
	fi
	sync
}

load_drastic_configs() {
	DS_DIR="/mnt/SDCARD/Emu/NDS/config"
	cp -f "$DS_DIR/drastic-$PLATFORM.cfg" "$DS_DIR/drastic.cfg"
}

save_drastic_configs() {
	DS_DIR="/mnt/SDCARD/Emu/NDS/config"
	cp -f "$DS_DIR/drastic.cfg" "$DS_DIR/drastic-$PLATFORM.cfg"
}

run_openbor() {
	export HOME=$EMU_DIR
	cd $HOME
	if [ "$PLATFORM" = "Brick" ]; then
		./OpenBOR_Brick "$ROM_FILE"
	elif [ "$PLATFORM" = "Flip" ]; then
		export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME
		./OpenBOR_Flip "$ROM_FILE"
	else # assume A30
		export LD_LIBRARY_PATH=lib:/usr/miyoo/lib:/usr/lib
		if [ "$GAME" = "Final Fight LNS.pak" ]; then
			./OpenBOR_mod "$ROM_FILE"
		else
			./OpenBOR_new "$ROM_FILE"
		fi
	fi
	sync
}

run_pico8() {
    # send signal USR2 to joystickinput to switch to KEYBOARD MODE
	# this allows joystick to be used as DPAD in MainUI
	killall -q -USR2 joystickinput

	# set 64-bit wget for BBS
	if ! [ "$PLATFORM" = "A30" ]; then
		WGET_PATH="$HOME"/bin64:
	fi

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

	# send signal USR1 to joystickinput to switch to ANALOG MODE
	killall -q -USR1 joystickinput
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

set_port_mode() {
    rm "/mnt/SDCARD/Persistent/portmaster/PortMaster/gamecontrollerdb.txt"
    if [ "$PORT_CONTROL" = "X360" ]; then
        cp "/mnt/SDCARD/Emu/PORTS/gamecontrollerdb_360.txt" "/mnt/SDCARD/Persistent/portmaster/PortMaster/gamecontrollerdb.txt"
    else
        cp "/mnt/SDCARD/Emu/PORTS/gamecontrollerdb_nintendo.txt" "/mnt/SDCARD/Persistent/portmaster/PortMaster/gamecontrollerdb.txt"
    fi
}

run_port() {
	if [ "$PLATFORM" = "Flip" ] || [ "$PLATFORM" = "Brick" ]; then
        /mnt/SDCARD/spruce/flip/bind-new-libmali.sh
        set_port_mode

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

	case "$PLATFORM" in
		"Brick" | "SmartPro" )
			export RA_BIN="ra64.trimui_$PLATFORM"
			if [ "$CORE" = "uae4arm" ]; then
				export LD_LIBRARY_PATH=$EMU_DIR:$LD_LIBRARY_PATH
			elif [ "$CORE" = "genesis_plus_gx" ] && [ "$PLATFORM" = "SmartPro" ] && \
				setting_get "genesis_plus_gx_wide"; then
				CORE="genesis_plus_gx_wide"
			fi
			# TODO: remove this once profile is set up
			export LD_LIBRARY_PATH=$EMU_DIR/lib64:$LD_LIBRARY_PATH
		;;
		"Flip" )
			if [ "$CORE" = "yabasanshiro" ]; then
				# "Error(s): /usr/miyoo/lib/libtmenu.so: undefined symbol: GetKeyShm" if you try to use non-Miyoo RA for this core
				export RA_BIN="ra64.miyoo"
			elif setting_get "expertRA" || [ "$CORE" = "km_parallel_n64_xtreme_amped_turbo" ]; then
				export RA_BIN="retroarch-flip"
			else
				export RA_BIN="ra64.miyoo"
			fi
			if [ "$CORE" = "easyrpg" ]; then
				export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$EMU_DIR/lib-Flip
			elif [ "$CORE" = "yabasanshiro" ]; then
				export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$EMU_DIR/lib64
			fi
		;;
		"A30" )
			# handle different version of ParaLLEl N64 core and flycast xtreme core for A30
			if [ "$CORE" = "parallel_n64" ]; then
				CORE="km_parallel_n64_xtreme_amped_turbo"
			elif [ "$CORE" = "flycast_xtreme" ]; then
				CORE="km_flycast_xtreme"
			fi

			if setting_get "expertRA" || [ "$CORE" = "km_parallel_n64_xtreme_amped_turbo" ]; then
				export RA_BIN="retroarch"
			else
				export RA_BIN="ra32.miyoo"
			fi
		;;
	esac

	RA_DIR="/mnt/SDCARD/RetroArch"
	cd "$RA_DIR"

	if [ "$PLATFORM" = "A30" ]; then
		CORE_DIR="$RA_DIR/.retroarch/cores"
	else # 64-bit device
		CORE_DIR="$RA_DIR/.retroarch/cores64"
	fi

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
		load_drastic_configs
		run_drastic
		save_drastic_configs
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
		ready_architecture_dependent_states
		run_retroarch
		stash_architecture_dependent_states
		;;
esac

kill -9 $(pgrep -f enforceSmartCPU.sh)
log_message "-----Closing Emulator-----" -v

auto_regen_tmp_update
