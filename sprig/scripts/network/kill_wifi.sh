#!/bin/sh

killall -USR2 udhcpc 2>/dev/null
sleep 1
ifconfig wlan0 down 2>/dev/null
sleep 1
killall -q adbd dropbear smbd telnetd syncthing udhcpc wpa_supplicant 2>/dev/null
