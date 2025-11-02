#!/bin/sh

export LD_LIBRARY_PATH="/mnt/SDCARD/sprig/lib:$LD_LIBRARY_PATH"

# Create necessary directories
mkdir -p /tmp/samba/private
mkdir -p /tmp/samba/lock
mkdir -p /tmp/samba/run

# Set the Samba password for the root user
PASSWORD="happygaming"
echo -ne "$PASSWORD\n$PASSWORD\n" | /mnt/SDCARD/sprig/bin/smbpasswd -c /mnt/SDCARD/sprig/etc/smb.conf -s -a sprig

# Start the Samba daemon
rm /tmp/samba/run/smbd-smb.conf.pid
LD_LIBRARY_PATH="$LD_LIBRARY_PATH" /mnt/SDCARD/sprig/bin/smbd -s /mnt/SDCARD/sprig/etc/smb.conf -D
