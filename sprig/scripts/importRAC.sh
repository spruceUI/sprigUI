#!/bin/sh

. /mnt/SDCARD/sprig/scripts/helperFunctions.sh

RAC_CFG=/mnt/SDCARD/RetroAchievementsLogin.cfg
RA_V4_CFG=/mnt/SDCARD/RetroArch/.retroarch/retroarchV4.cfg

if [ ! -f "$RAC_CFG" ]; then
    log_message "RetroAchievementsLogin.cfg not found" -v
    exit 2
fi

# Load credentials
. "$RAC_CFG"

if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    log_message "Username or password missing in RetroAchievementsLogin.cfg"
    exit 1
fi

# Ensure the target file exists
if [ ! -f "$RA_V4_CFG" ]; then
    log_message "retroarchV4.cfg not found"
    exit 3
fi

# Use a temporary file to avoid breaking the original during edits
tmpfile="$(mktemp)"

# Enable RetroAchievements and update fields using sed
sed -E \
    -e "s|^cheevos_enable = .*|cheevos_enable = \"true\"|" \
    -e "s|^cheevos_leaderboards_enable = .*|cheevos_leaderboards_enable = \"true\"|" \
    -e "s|^cheevos_badges_enable = .*|cheevos_badges_enable = \"true\"|" \
    -e "s|^cheevos_username = .*|cheevos_username = \"${USERNAME}\"|" \
    -e "s|^cheevos_password = .*|cheevos_password = \"${PASSWORD}\"|" \
    "$RA_V4_CFG" > "$tmpfile"

# For any fields that might not exist yet, append them if missing
grep -q '^cheevos_enable' "$tmpfile" || echo "cheevos_enable = \"true\"" >> "$tmpfile"
grep -q '^cheevos_username' "$tmpfile" || echo "cheevos_username = \"${USERNAME}\"" >> "$tmpfile"
grep -q '^cheevos_password' "$tmpfile" || echo "cheevos_password = \"${PASSWORD}\"" >> "$tmpfile"

# Move updated config back
mv "$tmpfile" "$RA_V4_CFG"

log_message "RetroAchievements credentials and settings applied successfully."
exit 0
