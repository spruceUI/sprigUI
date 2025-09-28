#!/bin/sh
echo $0 $*
progdir=`dirname "$0"`
homedir=`dirname "$1"`
cd $progdir
./cpufreq.sh

# Timer initialisation
cd /mnt/SDCARD/App/PlayActivity
./playActivity "init"

cd /mnt/SDCARD/RetroArch/
HOME=/mnt/SDCARD/RetroArch/ $progdir/../../RetroArch/retroarch -v -L $progdir/retro8_libretro.so "$1"


# Timer initialisation
cd /mnt/SDCARD/App/PlayActivity
./playActivity "$1"