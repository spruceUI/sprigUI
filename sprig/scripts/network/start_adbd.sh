#!/bin/sh

cd /mnt/SDCARD
export LD_LIBRARY_PATH="/mnt/SDCARD/sprig/lib:$LD_LIBRARY_PATH"
/mnt/SDCARD/sprig/bin/adbd &