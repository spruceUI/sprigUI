#!/bin/sh

RA_V4_CFG="/mnt/SDCARD/RetroArch/.retroarch/retroarchV4.cfg"
RAC_CFG="/mnt/SDCARD/RetroAchievementsLogin.cfg"

# Exit if credentials already exist in retroarchV4.cfg
grep -q '^cheevos_username = "[^"]\+"' "$RA_V4_CFG" && exit 0
grep -q '^cheevos_password = "[^"]\+"' "$RA_V4_CFG" && exit 0

# If login file doesn't exist, create it with instructions
if [ ! -f "$RAC_CFG" ]; then
    printf '# RetroAchievements Login File\n' > "$RAC_CFG"
    printf '# Fill in your credentials at https://retroachievements.org\n' >> "$RAC_CFG"
    printf 'export USERNAME=""\nexport PASSWORD=""\n' >> "$RAC_CFG"
    exit 0
fi

# Load credentials from login file
. "$RAC_CFG"

# Exit if either credential is empty
[ -n "$USERNAME" ] || exit 0
[ -n "$PASSWORD" ] || exit 0

# Escape for sed
ESC_USER=$(printf '%s' "$USERNAME" | sed 's/[\/&]/\\&/g')
ESC_PASS=$(printf '%s' "$PASSWORD" | sed 's/[\/&]/\\&/g')

# Update retroarchV4.cfg
sed -i \
  -e "s|^[[:space:]]*cheevos_username[[:space:]]*=.*$|cheevos_username = \"${ESC_USER}\"|" \
  -e "s|^[[:space:]]*cheevos_password[[:space:]]*=.*$|cheevos_password = \"${ESC_PASS}\"|" \
  -e "s|^[[:space:]]*cheevos_enable[[:space:]]*=.*$|cheevos_enable = \"true\"|" \
  "$RA_V4_CFG"

# Remove login file after copying
rm -f "$RAC_CFG"

exit 0
