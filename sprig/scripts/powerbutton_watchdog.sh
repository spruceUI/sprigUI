#!/bin/sh

. /mnt/SDCARD/sprig/helperFunctions.sh

while true; do

    /mnt/SDCARD/sprig/bin/getevent /dev/input/event0 | while read line; do

        case line in 
            *"key 1 116 1"* ) # power key depressed
                
            ;;

        esac

    done

done