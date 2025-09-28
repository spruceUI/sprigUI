#!/bin/sh
echo $0 $*
progdir=`dirname "$0"`
homedir=`dirname "$1"`
cd $progdir
./cpufreq.sh

# Timer initialisation
cd /mnt/SDCARD/App/PlayActivity
./playActivity "init"

HOME=$homedir $progdir/FAKE08 "$1"


# Timer initialisation
cd /mnt/SDCARD/App/PlayActivity
./playActivity "$1"