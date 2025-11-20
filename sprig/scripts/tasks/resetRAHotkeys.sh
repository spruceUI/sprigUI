#!/bin/sh

. /mnt/SDCARD/sprig/scripts/helperFunctions.sh

RA_FILE="/mnt/SDCARD/RetroArch/.retroarch/retroarchV4.cfg"

update_file() {
    file="$1"
    shift

    for setting in "$@"; do
        if grep -q "${setting%%=*}" "$file"; then
            sed -i "s|^${setting%%=*}.*|$setting|" "$file"
        else
            echo "$setting" >>"$file"
        fi
    done

    log_message "Updated $file"
}

log_message "Resetting RetroArch hotkeys to Spruce defaults."

# Update RetroArch config with default values


update_file "$RA_FILE" \
    "input_enable_hotkey = \"rctrl\"" \
    "input_exit_emulator = \"ctrl\"" \
    "input_fps_toggle = \"alt\"" \
    "input_load_state = \"e\"" \
    "input_menu_toggle = \"shift\"" \
    "input_menu_toggle_btn = \"9\"" \
    "input_quit_gamepad_combo = \"0\"" \
    "input_save_state = \"t\"" \
    "input_screenshot = \"space\"" \
    "input_shader_toggle = \"up\"" \
    "input_state_slot_decrease = \"left\"" \
    "input_state_slot_increase = \"right\"" \
    "input_toggle_slowmotion = \"tab\"" \
    "input_toggle_fast_forward = \"backspace\""

log_message "RetroArch hotkeys have been reset to defaults."
