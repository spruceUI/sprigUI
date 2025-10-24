#!/bin/sh

if [ -z "$1" ]; then
    duration=0.1
else
    duration="$1"
fi

echo 48 > /sys/class/gpio/export /dev/null 2>&1
echo out > /sys/class/gpio/gpio48/direction
sleep "$duration"
echo 1 > /sys/class/gpio/gpio48/value
