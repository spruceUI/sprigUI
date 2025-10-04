#!/bin/sh
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