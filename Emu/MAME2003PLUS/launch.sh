#!/bin/sh
echo $0 $*
RA_DIR=/mnt/SDCARD/RetroArch
swapon /mnt/SDCARD/App/swap/swap.img
cd $RA_DIR/
HOME=$RA_DIR/ $RA_DIR/ra32.ss -v -L $RA_DIR/.retroarch/cores/mame2003_xtreme_libretro.so "$1"
swapoff /mnt/SDCARD/App/swap/swap.img	