#!/bin/sh
echo $0 $*
RA_DIR=/mnt/SDCARD/RetroArch
swapon /mnt/SDCARD/App/swap/swap.img
cd $RA_DIR/
HOME=$RA_DIR/ $RA_DIR/retroarch -v -L $RA_DIR/.retroarch/cores/fb_32b_libretro.so "$1"
swapoff /mnt/SDCARD/App/swap/swap.img
