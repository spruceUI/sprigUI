#!/bin/sh
echo $0 $*
RA_DIR=/mnt/SDCARD/RetroArch
ROMNAME="$1"
BASEROMNAME=${ROMNAME##*/}
ROMNAMETMP=${BASEROMNAME%.*}

cd $RA_DIR/
if [ -f "../Roms/PSBIOS/${ROMNAMETMP}.bios" ]; then
		cp -f "../Roms/PSBIOS/${ROMNAMETMP}.bios" "../RetroArch/.retroarch/system/scph101.bin"
else
		cp -f "../Roms/PSBIOS/scph1001.bios" "../RetroArch/.retroarch/system/scph101.bin"
fi

cd $RA_DIR/
HOME=$RA_DIR/ $RA_DIR/retroarch -v -L $RA_DIR/.retroarch/cores/pcsx_rearmed_libretro.so "$1"


