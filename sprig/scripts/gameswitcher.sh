#!/bin/sh


if pgrep "retroarch" >/dev/null; then
	touch /mnt/SDCARD/App/PyUI/pyui_gs_trigger
	killall -q -15 retroarch
fi