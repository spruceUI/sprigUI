#!/bin/sh
###############
#get target ID#
###############
gameid=$(cat "$1")
progdir="$(dirname "$0")/../../App/scummvm"
cd $progdir

HOME=$progdir

export LD_LIBRARY_PATH="$progdir/lib:$LD_LIBRARY_PATH"
./scummvm $gameid
