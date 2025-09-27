#!/bin/sh
mydir=`dirname "$0"`
midir="/mnt/SDCARD/App/parasyte/rootfs"

export HOME=$mydir
export PATH=$mydir/bin:$midir/usr/local/sbin:$midir/usr/local/bin:$midir/usr/sbin:$midir/usr/bin:$midir/sbin:$midir/bin:$PATH
export LD_LIBRARY_PATH=$mydir/libs:$midir/lib:$midir/usr/lib:$LD_LIBRARY_PATH

cd $mydir
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
ffplay -vf "hflip,vflip" -i "$1"

