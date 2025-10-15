#!/bin/sh

mount -o bind /mnt/SDCARD/sprig/etc/profile /etc/profile

cd $(dirname "$0")
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.
./adbd &

