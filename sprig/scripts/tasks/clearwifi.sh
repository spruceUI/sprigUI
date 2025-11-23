#!/bin/sh

. /mnt/SDCARD/sprig/scripts/helperFunctions.sh

# Bring the Wi-Fi interface down
/mnt/SDCARD/sprig/scripts/network/kill_wifi.sh

# Remove all networks
echo -e "ctrl_interface=DIR=/var/run/wpa_supplicant\nupdate_config=1" | tee "$WPA_SUPPLICANT_FILE" "${WPA_SUPPLICANT_FILE}.tmp"
log_message "Wifi: All networks forgotten by request of user."

# Bring interface and services back up
/mnt/SDCARD/sprig/scripts/network/start_wifi.sh
/mnt/SDCARD/sprig/scripts/network/start_stop_services.sh
