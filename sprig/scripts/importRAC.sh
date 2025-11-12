#!/bin/sh
RA_V4_CFG="/mnt/SDCARD/RetroArch/.retroarch/retroarchV4.cfg"
RAC_CFG="/mnt/SDCARD/RetroAchievementsLogin.cfg"

# Exit if retroarch already has BOTH credentials
if grep -q '^cheevos_username = "[^"]\+"' "$RA_V4_CFG" && \
   grep -q '^cheevos_password = "[^"]\+"' "$RA_V4_CFG"; then
    exit 0
fi

# Exit if login file doesn't exist
[ -f "$RAC_CFG" ] || exit 0

# Load credentials from file
. "$RAC_CFG"

# Exit if username or password is missing/empty
[ -n "$USERNAME" ] && [ -n "$PASSWORD" ] || exit 0

# Escape special characters for sed
ESC_USER=$(printf '%s' "$USERNAME" | sed 's/[\/&]/\\&/g')
ESC_PASS=$(printf '%s' "$PASSWORD" | sed 's/[\/&]/\\&/g')

# Update RetroArch config
sed -i \
  -e 's|cheevos_username = ""|cheevos_username = "'"${ESC_USER}"'"|' \
  -e 's|cheevos_password = ""|cheevos_password = "'"${ESC_PASS}"'"|' \
  -e 's|cheevos_enable = "false"|cheevos_enable = "true"|' \
  "$RA_V4_CFG"

# Delete login file after copying
rm -f "$RAC_CFG"
exit 0