#!/bin/sh
mydir=`dirname "$0"`


export HOME=$mydir
export FONTCONFIG_PATH=$mydir/fonts
export LD_LIBRARY_PATH=$mydir/libs:$LD_LIBRARY_PATH

cd $mydir
./green "$1"
