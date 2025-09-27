#!/bin/sh
echo $0 $*
progdir=`dirname "$0"`
cd $progdir
HOME=$progdir
export LD_LIBRARY_PATH=$progdir:$LD_LIBRARY_PATH
filename=${1##*/}
if grep ",$filename" $progdir/mame.txt > /dev/null;then
	$progdir/retroarch-onion -v -L $progdir/.retroarch/cores/mame2003_plus_libretro.so "$1"
else
	$progdir/retroarch -v -L $progdir/.retroarch/cores/fbneo_libretro.so "$1"
fi