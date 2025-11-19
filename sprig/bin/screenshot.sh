#!/bin/sh

/mnt/SDCARD/sprig/bin/fbgrab -a "/tmp/screenshot.png" 2>/dev/null 
rm "$1"
/mnt/SDCARD/sprig/bin/ffmpeg -i "/tmp/screenshot.png" -vf "rotate=PI" "$1"
