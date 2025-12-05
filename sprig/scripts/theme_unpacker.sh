#!/bin/sh

. /mnt/SDCARD/sprig/scripts/helperFunctions.sh

THEME_DIR="/mnt/SDCARD/Themes"

# Function to unpack archives from a specified directory
unpack_archives() {
    local dir="$1"

    for archive in "$dir"/*.7z; do
        if [ -f "$archive" ]; then
            archive_name=$(basename "$archive" .7z)
            log_and_display_message "$archive_name archive detected. Unpacking.........."

            if 7zr l "$archive" | grep -q "/mnt/SDCARD/"; then
                if 7zr x -aoa "$archive" -o/; then
                    rm -f "$archive"
                    log_message "Unpacker: Unpacked and removed: $archive_name.7z"
                else
                    log_message "Unpacker: Failed to unpack: $archive_name.7z"
                fi
            else
                log_message "Unpacker: Skipped unpacking: $archive_name.7z (incorrect folder structure)"
            fi
        fi
    done
}

# Quick check for .7z files in relevant directories
if [ -z "$(find "$THEME_DIR" -maxdepth 1 -name '*.7z' | head -n 1)" ]; then
    log_message "Unpacker: No .7z files found to unpack. Exiting."
    exit 0
fi

log_message "Unpacker: Starting theme unpacking process"

start_pyui_message_writer
unpack_archives "$THEME_DIR"
log_and_display_message "Done!"
sleep 2
