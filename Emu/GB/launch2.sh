#!/bin/sh
echo $0 $*
RA_DIR=/mnt/SDCARD/RetroArch
EMU_DIR=/mnt/SDCARD/Emu/GB


cd $RA_DIR/
HOME=$RA_DIR/ LD_PRELOAD=$EMU_DIR/libstdc++.so.6 $RA_DIR/retroarch -v -L $RA_DIR/.retroarch/cores/DoubleCherryGB_libretro.so "$1"
