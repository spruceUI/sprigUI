#!/bin/sh

if [ -z "$1" ]; then
    duration=0.1
else
    duration="$1"
fi

if [ -z "$2" ]; then
    repetitions=1
else
    repetitions="$2"
fi

if [ -z "$3" ]; then
    downtime="$duration"
else
    downtime="$3"
fi

echo 48 > /sys/class/gpio/export >/dev/null 2>&1
while [ "$repetitions" -gt 0 ]; do
    echo out > /sys/class/gpio/gpio48/direction
    sleep "$duration"
    echo 1 > /sys/class/gpio/gpio48/value
    sleep "$downtime"
    repetitions=$((repetitions - 1))
done
