#!/bin/sh

. /mnt/SDCARD/sprig/helperFunctions.sh
export PATH="/mnt/SDCARD/sprig/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/sprig/lib:$LD_LIBRARY_PATH:/mnt/SDCARD/App/PyUI/libs/:/config/lib/:/customer/lib"

DOWNLOAD="/mnt/SDCARD/App/GameNursery/download_game.sh"
CONFIG_DIR="/mnt/SDCARD/Saves/GameNursery"
JSON_DIR="/tmp/nursery-json"
JSON_URL="https://github.com/spruceUI/Ports-and-Free-Games/releases/download/Singles/_info.7z"
JSON_CACHE_VALID_MINUTES=10

is_wifi_connected() {
    if ping -c 3 -W 2 1.1.1.1 > /dev/null 2>&1; then
        log_message "Cloudflare ping successful; device is online."
        return 0
    else
        log_and_display_message "Cloudflare ping failed; device is offline. Aborting."
        return 1
    fi
}

is_json_valid() {
    mkdir "$JSON_DIR" 2>/dev/null
    cd "$JSON_DIR"
    if [ -f "$JSON_DIR/INFO.7z" ]; then
        file_age_minutes=$(( ($(date +%s) - $(date -r "$JSON_DIR/INFO.7z" +%s)) / 60 ))
        
        if [ "$file_age_minutes" -lt "$JSON_CACHE_VALID_MINUTES" ]; then
            # Check if we have at least one extracted directory with jsons
            if [ -d "$JSON_DIR" ] && [ "$(find "$JSON_DIR" -mindepth 1 -type d)" ]; then
                log_message "Game Nursery: Cache is valid (less than $JSON_CACHE_VALID_MINUTES minutes old)"
                return 0
            fi
            # If no extracted files found, we'll continue to extraction but won't redownload
            log_message "Game Nursery: Cache exists but needs extraction"
            if ! 7zr x -y -scsUTF-8 "$JSON_DIR/INFO.7z" >/dev/null 2>&1; then
                rm -f "$JSON_DIR/INFO.7z" >/dev/null 2>&1
                log_message "Game Nursery: Existing cache could not be extracted."
                return 1
            else
                log_message "Game Nursery: Existing cache extracted successfully."
                return 0
            fi
        fi
    else        # no INFO.7z exists, so not valid.
        return 1
    fi
}

get_latest_jsons() {
    # Clear directory only if we need to download new files
    mkdir "$JSON_DIR" 2>/dev/null
    cd "$JSON_DIR"
    rm -r ./* 2>/dev/null

    if ! wget --quiet --no-check-certificate --max-redirect=20 -O "$JSON_DIR/INFO.7z" "$JSON_URL"; then
        log_and_display_message "Unable to download latest info files from repository. Please try again later."
        sleep 3
        exit 1
    fi

    log_message "Game Nursery: Info cache downloaded successfully"

    if ! 7zr x -y -scsUTF-8 "$JSON_DIR/INFO.7z" >/dev/null 2>&1; then
        log_and_display_message "Unable to extract latest game info files. Please try again later."
        sleep 3
        rm -f "$JSON_DIR/INFO.7z" >/dev/null 2>&1
        exit 1
    fi
    log_message "Game Nursery: JSON extraction process completed successfully"

    # remove existing nursery_config so we can rebuild it with updated info
    rm -f "$CONFIG_DIR/nursery_config" 2>/dev/null
}

interpret_json() {

    json_file="$1"
    display_name="$(jq -r '.display' "$json_file")"
    group_name="$(basename "$(dirname "$json_file")")"    # file="$(jq -r '.file' "$json_file")"

    # add line for specific game
    echo "\"$group_name/$display_name\": \"$DOWNLOAD '$json_file'\","
}

download_boxart() {
    local json_file="$1"
    local display_name system group_name img_url img_path

    display_name="$(jq -r '.display' "$json_file" | tr -d '\r\n')"
    system="$(jq -r '.system' "$json_file")"
    group_name="$(basename "$(dirname "$json_file")")"

    # Construct local destination
    img_path="$CONFIG_DIR/Imgs/${display_name}.png"

    log_message "Checking for cached boxart at: $img_path" -v
    if [ -e "$img_path" ]; then
        log_message "Game Nursery: Box art for '$display_name' already cached. Skipping download."
        return 0
    fi

    # Construct GitHub raw URL for the boxart
    img_url="https://raw.githubusercontent.com/spruceUI/Ports-and-Free-Games/main/${group_name}/${display_name}/Roms/${system}/Imgs/${display_name}.png"

    # Ensure directory exists
    mkdir -p "$(dirname "$img_path")"

    if wget --quiet --no-check-certificate -O "$img_path" "$img_url"; then
        log_message "Game Nursery: Successfully downloaded boxart for '$display_name'"
        resize_image "$img_path"
    else
        log_message "Game Nursery: Failed to download boxart for '$display_name'"
        rm -f "$img_path"
    fi
}

resize_image() {
    local image_path="$1"
    local full_width=450
    local full_height=450

    # Ensure image exists
    [ -f "$image_path" ] || { echo "File not found: $image_path"; return 1; }

    local dir base tmp_path
    dir=$(dirname "$image_path")
    base=$(basename "$image_path")
    tmp_path="$dir/tmp_$base"
    
    log_message "Resizing $image_path to $full_width x $full_height max."
    # Resize while preserving aspect ratio
    ffmpeg -y -i "$image_path" \
        -vf "scale='min($full_width,iw)':'min($full_height,ih)':force_original_aspect_ratio=decrease" \
        "$tmp_path"

    if [ -f "$tmp_path" ]; then
        mv "$tmp_path" "$image_path"
    else
        log_message "Resize failed — ffmpeg did not produce $tmp_path"
        return 1
    fi

    return 0
}

is_config_valid() {
    local config_file="$CONFIG_DIR/nursery_config"

    # Check that the config file exists and isn't empty
    if [ ! -f "$config_file" ] || [ ! -s "$config_file" ]; then
        log_message "Game Nursery: nursery_config missing or empty. Rebuilding."
        return 1
    fi

    # Validate JSON structure
    if ! jq empty "$config_file" >/dev/null 2>&1; then
        log_message "Game Nursery: nursery_config is invalid JSON. Rebuilding."
        return 1
    fi

    log_message "Game Nursery: Existing nursery_config is valid."
    return 0
}

construct_config() {
    mkdir "$CONFIG_DIR" 2>/dev/null
    cd "$CONFIG_DIR"
    
    # Clear and rebuild if we get here
    rm -f "$CONFIG_DIR/nursery_config" 2>/dev/null

    # Initialize config json with open bracket
    echo "{" > "$CONFIG_DIR"/nursery_config

    # loop through each folder of game jsons
    for group_dir in "$JSON_DIR"/*; do

        # make sure it's a non-empty directory before trying to do stuff
        if [ -d "$group_dir" ] && [ -n "$(ls "$group_dir")" ]; then

            # create tab for a given group of games
            tab_name="$(basename "$group_dir")"
            if [ ! "$tab_name" = "Ports" ]; then
                # iterate through each json for the current group
                for filename in "$group_dir"/*.json; do
                    interpret_json "$filename" >> "$CONFIG_DIR"/nursery_config
                    download_boxart "$filename"
                done
            fi
        fi
    done

    sed -i '$ s/,$//' "$CONFIG_DIR"/nursery_config      # strip away final trailing comma
    echo "}" >> "$CONFIG_DIR"/nursery_config            # Finish config json with a closing bracket
}


##### MAIN EXECUTION #####

start_pyui_message_writer
log_and_display_message "Welcome to the sprigUI Game Nursery, where you can pick the freshest homegrown games! Please wait.........."

if ! is_wifi_connected; then sleep 3; exit 1; fi
if ! is_json_valid; then get_latest_jsons; fi
if ! is_config_valid; then construct_config; fi

stop_pyui_message_writer

rm -f /tmp/exit_nursery
while [ ! -e /tmp/exit_nursery ]; do
    touch /tmp/exit_nursery
    freemma
    /mnt/SDCARD/App/PyUI/launch.sh -optionListTitle "Game Nursery" -optionListFile "$CONFIG_DIR"/nursery_config
done