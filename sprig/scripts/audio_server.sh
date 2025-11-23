#!/bin/sh

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/config:/customer/app
export LD_LIBRARY_PATH=/lib:/config/lib:/mnt/SDCARD/miyoo285//lib

unset LD_PRELOAD
unset LD_AUDIT
unset LD_SO_PRELOAD
unset LIBRARY_PATH
unset LD_RUN_PATH
unset LD_LIBRARY_PATH_32
unset LD_LIBRARY_PATH_64
unset DYLD_LIBRARY_PATH
unset DYLD_FALLBACK_LIBRARY_PATH
unset PKG_CONFIG_PATH
unset XDG_DATA_DIRS
unset XDG_CONFIG_DIRS

export USER=root
export HOME=/
export TERMINFO=/config/terminfo
export TERM=vt102
export SHELL=/bin/sh

# --- Call audioserver with whatever args are passed ---
# -3 was passed based on my config but we should probably calculate it

if ps | grep '[a]udioserver'; then
    echo "audioserver is already running"
    exit 0
fi

/mnt/SDCARD/miyoo285/app/audioserver "$@" &