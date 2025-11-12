#!/bin/sh
RA_V4_CFG="/mnt/SDCARD/RetroArch/.retroarch/retroarchV4.cfg"
RAC_CFG="/mnt/SDCARD/RetroAchievementsLogin.cfg"

grep -q '^cheevos_username = "[^"]\+"' "$RA_V4_CFG" && exit 0
grep -q '^cheevos_password = "[^"]\+"' "$RA_V4_CFG" && exit 0

[ -f "$RAC_CFG" ] || {
    printf 'export USERNAME=""\nexport PASSWORD=""\n' > "$RAC_CFG"
}

exit 0
