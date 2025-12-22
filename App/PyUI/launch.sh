#!/bin/sh

get_device() {
    if [ -e /customer/app/axp_test ]; then
        if grep -q "752x560p" /sys/class/graphics/fb0/modes &>/dev/null ; then
            echo "SPRIG_MIYOO_MINI_FLIP"
        else
            echo "SPRIG_MIYOO_MINI_PLUS"
        fi
    else
        if grep -q "752x560p" /sys/class/graphics/fb0/modes &>/dev/null ; then
            echo "SPRIG_MIYOO_MINI_V4"
        else
            echo "SPRIG_MIYOO_MINI"
        fi
    fi

}

##### MAIN #####

skip_freemma=0
redirect_output=1

for arg in "$@"; do
    if [ "$arg" = "-buttonListenerMode" ]; then
        skip_freemma=1
        redirect_output=0
        break
    fi
done

if [ $skip_freemma -eq 0 ]; then
    freemma
fi

device="$(get_device)"

export PATH="/mnt/SDCARD/sprig/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/sprig/lib/:/config/lib/:/customer/lib"
export PYSDL2_DLL_PATH="/mnt/SDCARD/sprig/lib"

export SDL_VIDEODRIVER=mmiyoo
export SDL_AUDIODRIVER=mmiyoo
export EGL_VIDEODRIVER=mmiyoo
export SDL_MMIYOO_DOUBLE_BUFFER=1

rm /mnt/SDCARD/App/PyUI/run.txt

# Base command
cmd="MainUI /mnt/SDCARD/App/PyUI/main-ui/mainui.py -device $device -logDir /mnt/SDCARD/App/PyUI/logs -pyUiConfig /mnt/SDCARD/App/PyUI/py-ui-config.json -cfwConfig /mnt/SDCARD/Saves/sprig/sprig-config.json"

if [ $redirect_output -eq 1 ]; then
    # Use `sh -c` to safely expand arguments
    sh -c "$cmd \"\$@\" >> /mnt/SDCARD/App/PyUI/run.txt 2>&1" sh "$@"
else
    sh -c "$cmd \"\$@\"" sh "$@"
fi
