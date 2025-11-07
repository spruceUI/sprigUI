#!/bin/sh

. /mnt/SDCARD/sprig/helperFunctions.sh
export PATH="/mnt/SDCARD/sprig/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/sprig/lib:$LD_LIBRARY_PATH:/mnt/SDCARD/App/PyUI/libs/:/config/lib/:/customer/lib"

DOWNLOAD="/mnt/SDCARD/App/GameNursery/download_game.sh"
CONFIG_DIR="/tmp/nursery-config"
JSON_DIR="/tmp/nursery-json"
JSON_URL="https://github.com/spruceUI/Ports-and-Free-Games/releases/download/Singles/_info.7z"
DEV_JSON_URL="https://github.com/spruceUI/Ports-and-Free-Games/releases/download/Singles/_test.7z"
JSON_CACHE_VALID_MINUTES=10

is_wifi_connected() {
    if ping -c 3 -W 2 1.1.1.1 > /dev/null 2>&1; then
        log_message "Cloudflare ping successful; device is online."
        return 0
    else
        start_pyui_message_writer
        log_and_display_message "Cloudflare ping failed; device is offline. Aborting."
        return 1
    fi
}

get_latest_jsons() {
    mkdir "$JSON_DIR" 2>/dev/null
    cd "$JSON_DIR"
    
    NEEDS_CONFIG_REBUILD=0

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
                NEEDS_CONFIG_REBUILD=1
            else
                NEEDS_CONFIG_REBUILD=1
                return 0
            fi
        fi
    fi

    # Clear directory only if we need to download new files
    rm -r ./* 2>/dev/null
    NEEDS_CONFIG_REBUILD=1

    download_json() {
        local url="$1"
        if wget --quiet --no-check-certificate --max-redirect=20 -O "$JSON_DIR/INFO.7z" "$url"; then
            return 0
        fi
        return 1
    }

    if ! download_json "$JSON_URL"; then
        start_pyui_message_writer
        log_and_display_message "Unable to download latest info files from repository. Please try again later."
        sleep 3
        exit 1
    fi
    log_message "Game Nursery: Info cache downloaded successfully"

    if ! 7zr x -y -scsUTF-8 "$JSON_DIR/INFO.7z" >/dev/null 2>&1; then
        start_pyui_message_writer
        log_and_display_message "Unable to extract latest game info files. Please try again later."
        sleep 3
        rm -f "$JSON_DIR/INFO.7z" >/dev/null 2>&1
        exit 1
    fi
    log_message "Game Nursery: JSON extraction process completed successfully"
}

interpret_json() {

    json_file="$1"
    display_name="$(jq -r '.display' "$json_file")"
    system="$(jq -r '.system' "$json_file")"
    # file="$(jq -r '.file' "$json_file")"
    # description="$(jq -r '.description' "$json_file")"
    # requires_files="$(jq -r '.requires_files' "$json_file")"
    # version="$(jq -r '.version' "$json_file")"

    # add notice that additional files are needed
    if [ "$requires_files" = "true" ]; then
        description="$description Requires additional files."
    fi

    # add line for specific game
    echo "\"$system/$display_name\": \"$DOWNLOAD '$json_file'\","
}

construct_config() {
    mkdir "$CONFIG_DIR" 2>/dev/null
    cd "$CONFIG_DIR"
    
    # Only keep existing config if we haven't downloaded new JSONs
    if [ "$NEEDS_CONFIG_REBUILD" -eq 0 ] && [ -f "$CONFIG_DIR/nursery_config" ] && [ -s "$CONFIG_DIR/nursery_config" ]; then
        log_message "Game Nursery: Using existing nursery_config"
        return 0
    fi

    # Clear and rebuild if we get here
    rm -r ./* 2>/dev/null

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
                done
            fi
        fi
    done

    # strip away final trailing comma
    sed -i '$ s/,$//' "$CONFIG_DIR"/nursery_config

    # Finish config json with a closing bracket
    echo "}" >> "$CONFIG_DIR"/nursery_config

}


##### MAIN EXECUTION #####

if ! is_wifi_connected; then sleep 3; exit 1; fi
get_latest_jsons
construct_config
/mnt/SDCARD/App/PyUI/launch.sh -optionListTitle "Game Nursery" -optionListFile "$CONFIG_DIR"/nursery_config
