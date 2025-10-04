#!/bin/sh

. "/mnt/SDCARD/sprig/helperFunctions.sh"
POLICY_DIR="$CPU_DIR/policy0"
GOVERNOR_FILE="$POLICY_DIR"/scaling_governor
sleep 10
governor="$(cat "$GOVERNOR_FILE")"
if [ "$governor" != "ondemand" ]; then
	# lock menu button to prevent ra32 menu from changing governor before we can lock out its write permission
	log_message "CPU governor is not set to ondemand. Re-enforcing SMART mode"
	set_smart
fi