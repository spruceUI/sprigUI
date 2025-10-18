#!/bin/sh

. "/mnt/SDCARD/sprig/helperFunctions.sh"

CPU_DIR="/sys/devices/system/cpu/cpufreq"
POLICY_DIR="$CPU_DIR/policy0"
GOVERNOR_FILE="$POLICY_DIR"/scaling_governor
sleep 10
governor="$(cat "$GOVERNOR_FILE")"
if [ "$governor" != "ondemand" ]; then
	log_message "CPU governor is not set to ondemand. Re-enforcing SMART mode"
	set_smart
fi