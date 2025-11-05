#!/bin/sh

# safe to attempt even if it's already up
ifconfig wlan0 up 2>/dev/null
sleep 1

# only bring up wpa_supplicant if not already running.
if ! killall -0 wpa_supplicant 2>/dev/null; then
    wpa_supplicant -B -i wlan0 -c /appconfigs/wpa_supplicant.conf
fi

# only bring up udhcpc if not already running.
if ! killall -0 udhcpc 2>/dev/null; then
    udhcpc -i wlan0 -q -t 5
fi