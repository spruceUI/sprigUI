#!/bin/sh
echo $0 $*
RA_DIR=/mnt/SDCARD/RetroArch
cd $RA_DIR/
HOME=$RA_DIR/ $RA_DIR/ra32.ss -v -L $RA_DIR/.retroarch/cores/fbneo_libretro.so "$1"
