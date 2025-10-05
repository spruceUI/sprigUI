#!/bin/sh

export LD_LIBRARY_PATH="/mnt/SDCARD/App/PyUI/libs/:/config/lib/:/customer/lib"
export PYSDL2_DLL_PATH="/mnt/SDCARD/App/PyUI/libs"

export SDL_VIDEODRIVER=mmiyoo
export SDL_AUDIODRIVER=mmiyoo
export EGL_VIDEODRIVER=mmiyoo
export SDL_MMIYOO_DOUBLE_BUFFER=1

rm /mnt/SDCARD/App/PyUI/run.txt
/mnt/SDCARD/App/PyUI/python3.10/bin/MainUI /mnt/SDCARD/App/PyUI/main-ui/mainui.py -device MIYOO_MINI_FLIP -logDir "/mnt/SDCARD/App/PyUI/logs" -pyUiConfig "/mnt/SDCARD/App/PyUI/py-ui-config.json" >> /mnt/SDCARD/App/PyUI/run.txt 2>&1
