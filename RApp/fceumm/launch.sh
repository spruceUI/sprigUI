#!/bin/sh
echo $0 $*
RA_DIR=/mnt/SDCARD/RetroArch
cd $RA_DIR/
HOME=$RA_DIR/ $RA_DIR/retroarch -v -L $RA_DIR/.retroarch/cores/fceumm_libretro.so "$1"
