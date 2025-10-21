#!/bin/sh

cd /mnt/SDCARD
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/mnt/SDCARD/sprig/lib
/mnt/SDCARD/sprig/bin/adbd &