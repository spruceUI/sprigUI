#!/bin/sh
RA_V4_CFG="/mnt/SDCARD/RetroArch/.retroarch/retroarch.cfg"
RAC_CFG="/mnt/SDCARD/RetroAchievementsLogin.cfg"

create_fresh_rac_cfg() {
    echo '# RetroAchievements Login File'
    echo '# Fill in the empty quotes below with your credentials.'
    echo '# Keep the quotes! '
    echo '# Example: '
    echo '# export USERNAME="YourUsername"'
    echo '# export PASSWORD="SuperSecretPassword"'
    echo ''
    echo 'export USERNAME=""'
    echo 'export PASSWORD=""'
    echo ''
}

[ -f "$RA_V4_CFG" ] || exit 5      ### exit if actual RA config doesn't exist

# Exit if login file doesn't exist
[ -f "$RAC_CFG" ] || create_fresh_rac_cfg > "$RAC_CFG"

# Load credentials from file
. "$RAC_CFG"

# Exit if username or password is missing/empty
[ -n "$USERNAME" ] && [ -n "$PASSWORD" ] || exit 1

# Escape special characters for sed
ESC_USER=$(printf '%s' "$USERNAME" | sed 's/[\/&]/\\&/g')
ESC_PASS=$(printf '%s' "$PASSWORD" | sed 's/[\/&]/\\&/g')

# Update RetroArch config
sed -i \
  -e 's|cheevos_username =.*$|cheevos_username = "'"${ESC_USER}"'"|' \
  -e 's|cheevos_password =.*$|cheevos_password = "'"${ESC_PASS}"'"|' \
  -e 's|cheevos_enable = "false"|cheevos_enable = "true"|' \
  "$RA_V4_CFG"

# empty out login file after copying
create_fresh_rac_cfg > "$RAC_CFG"
exit 0