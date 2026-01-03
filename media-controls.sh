#!/usr/bin/env bash

# Path for cached cover art
COVER="/tmp/player_cover.jpg"

# Function to fetch player info and update YAD
get_info() {
    local title artist cover_url status icon text menu

    # Fetch metadata
    title=$(playerctl metadata title 2>/dev/null)
    artist=$(playerctl metadata artist 2>/dev/null)
    cover_url=$(playerctl metadata mpris:artUrl 2>/dev/null | tr -d '"')

    # Download cover only if URL changed
    if [[ -n "$cover_url" && "$cover_url" != "$LAST_COVER_URL" ]]; then
        curl -s "$cover_url" -o "$COVER"
        LAST_COVER_URL="$cover_url"
    fi

    # Determine status icon
    status=$(playerctl status 2>/dev/null)
    case "$status" in
        Playing) icon="" ;;   # Play
        Paused)  icon="" ;;   # Pause
        Stopped) icon="" ;;   # Stop
        *)       icon="" ;;
    esac

    # Tooltip text
    text="Now Playing: ${title:-Unknown} by ${artist:-Unknown}"

    # YAD menu
    menu="${title:-Unknown} - ${artist:-Unknown}| Next!playerctl next| Previous!playerctl previous|$icon Play/Pause!playerctl play-pause"

    # Send updates to YAD
    echo "icon:${COVER}"
    echo "tooltip:${text}"
    echo "menu:${menu}"
}

# Start YAD with dynamic updates
(
    echo "tooltip:Loading..."
    LAST_TITLE=""
    LAST_COVER_URL=""
    while true; do
        TITLE=$(playerctl metadata title 2>/dev/null)
        if [[ "$TITLE" != "$LAST_TITLE" ]]; then
            get_info
            LAST_TITLE="$TITLE"
        fi
        sleep 1
    done
) | yad --notification --listen --command="playerctl play-pause" --icon-size=64 --no-middle
