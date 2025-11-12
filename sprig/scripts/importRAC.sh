#!/bin/sh

RA_V4_CFG="/mnt/SDCARD/RetroArch/.retroarch/retroarchV4.cfg"
RAC_CFG="/mnt/SDCARD/RetroAchievementsLogin.cfg"

# Exit if credentials already exist
grep -q '^cheevos_username = "[^"]\+"' "$RA_V4_CFG" && exit 0
grep -q '^cheevos_password = "[^"]\+"' "$RA_V4_CFG" && exit 0

# Create login file with instructions if missing
if [ ! -f "$RAC_CFG" ]; then
    printf '# RetroAchievements Login File\n' > "$RAC_CFG"
    printf '# Fill in your credentials at https://retroachievements.org\n' >> "$RAC_CFG"
    printf 'export USERNAME=""\nexport PASSWORD=""\n' >> "$RAC_CFG"
    exit 0
fi

# Load credentials
. "$RAC_CFG"

# Exit if empty
[ -n "$USERNAME" ] || exit 0
[ -n "$PASSWORD" ] || exit 0

# Escape for sed
ESC_USER=$(printf '%s' "$USERNAME" | sed 's/[\/&]/\\&/g')
ESC_PASS=$(printf '%s' "$PASSWORD" | sed 's/[\/&]/\\&/g')

# Replace exact lines
sed -i \
  -e 's|cheevos_username = ""|cheevos_username = "'"${ESC_USER}"'"|' \
  -e 's|cheevos_password = ""|cheevos_password = "'"${ESC_PASS}"'"|' \
  -e 's|cheevos_enable = "false"|cheevos_enable = "true"|' \
  "$RA_V4_CFG"

# Delete login file after copying
rm -f "$RAC_CFG"

exit 0
