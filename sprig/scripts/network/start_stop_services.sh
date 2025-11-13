#!/bin/sh
. /mnt/SDCARD/sprig/scripts/helperFunctions.sh

# Early out if wifi is disabled in PyUI
WIFI_ENABLED="$(get_pyui_config_value '.wifi' 1)"
[ "$WIFI_ENABLED" -ne 1 ] && exit 0

# Start network services if necessary
ADB_ENABLED="$(get_config_value '.menuOptions."Network Settings".enableADB.selected' "True")"
SSH_ENABLED="$(get_config_value '.menuOptions."Network Settings".enableSSH.selected' "False")"
SMB_ENABLED="$(get_config_value '.menuOptions."Network Settings".enableSMB.selected' "False")"
TEL_ENABLED="$(get_config_value '.menuOptions."Network Settings".enableTelnet.selected' "False")"
SYN_ENABLED="$(get_config_value '.menuOptions."Network Settings".enableSyncthing.selected' "False")"

# ADB
if [ "$ADB_ENABLED" = "True" ]; then
    if ! pgrep adbd >/dev/null 2>&1; then
        /mnt/SDCARD/sprig/scripts/network/start_adbd.sh &
        log_message "Started ADB daemon"
    fi
else
    killall adbd 2>/dev/null && log_message "Killed ADB daemon"
fi

# SSH (Dropbear)
if [ "$SSH_ENABLED" = "True" ]; then
    if ! pgrep dropbearmulti >/dev/null 2>&1; then
        /mnt/SDCARD/sprig/scripts/network/start_dropbear.sh &
        log_message "Started Dropbear"
    fi
else
    killall dropbear 2>/dev/null && log_message "Killed Dropbear"
fi

# SMB
if [ "$SMB_ENABLED" = "True" ]; then
    if ! pgrep smbd >/dev/null 2>&1; then
        /mnt/SDCARD/sprig/scripts/network/start_samba.sh &
        log_message "Started Samba daemon"
    fi
else
    killall smbd 2>/dev/null && log_message "Killed Samba daemon"
fi

# Telnet
if [ "$TEL_ENABLED" = "True" ]; then
    if ! pgrep telnetd >/dev/null 2>&1; then
        /usr/sbin/telnetd -l /bin/sh
        log_message "Started Telnet daemon"
    fi
else
    killall telnetd 2>/dev/null && log_message "Killed Telnet daemon"
fi

# Syncthing
if [ "$SYN_ENABLED" = "True" ]; then
    if ! pgrep syncthing >/dev/null 2>&1; then
      /mnt/SDCARD/sprig/scripts/network/start_syncthing.sh &
      log_message "Started Syncthing daemon"
    fi
else
    killall syncthing 2>/dev/null && log_message "Killed Syncthing daemon"
fi
