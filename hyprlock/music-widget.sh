#!/usr/bin/env bash

# Music widget script for hyprlock with animations and album artwork
# Returns different components based on the argument passed

ARTWORK_PATH="/tmp/current-album-art.jpg"
ARTWORK_CACHE="/tmp/album-art-cache.txt"

get_music_status() {
    playerctl status 2>/dev/null || echo "Stopped"
}

get_album_artwork() {
    local status=$(get_music_status)
    
    if [[ "$status" != "Playing" && "$status" != "Paused" ]]; then
        echo ""
        return
    fi
    
    local art_url=$(playerctl metadata --format "{{ mpris:artUrl }}" 2>/dev/null || echo "")
    local track_id=$(playerctl metadata --format "{{ artist }}-{{ title }}" 2>/dev/null || echo "unknown")
    
    # Check if we need to download new artwork
    local cached_track=""
    if [[ -f "$ARTWORK_CACHE" ]]; then
        cached_track=$(cat "$ARTWORK_CACHE")
    fi
    
    # If track changed or no cached artwork, download new one
    if [[ "$cached_track" != "$track_id" ]] || [[ ! -f "$ARTWORK_PATH" ]]; then
        if [[ -n "$art_url" && "$art_url" != "file://" ]]; then
            # Download artwork
            curl -s -L "$art_url" -o "$ARTWORK_PATH" 2>/dev/null
            if [[ $? -eq 0 && -f "$ARTWORK_PATH" ]]; then
                echo "$track_id" > "$ARTWORK_CACHE"
                echo "$ARTWORK_PATH"
            else
                # Download failed, use placeholder or remove cache
                rm -f "$ARTWORK_PATH" "$ARTWORK_CACHE" 2>/dev/null
                echo ""
            fi
        else
            # No artwork URL available
            rm -f "$ARTWORK_PATH" "$ARTWORK_CACHE" 2>/dev/null
            echo ""
        fi
    else
        # Use cached artwork
        if [[ -f "$ARTWORK_PATH" ]]; then
            echo "$ARTWORK_PATH"
        else
            echo ""
        fi
    fi
}

get_animated_bar() {
    local status=$(get_music_status)
    
    if [[ "$status" != "Playing" && "$status" != "Paused" ]]; then
        echo ""
        return
    fi
    
    # Get current position and duration in microseconds
    local position=$(playerctl metadata --format "{{ position }}" 2>/dev/null || echo "0")
    local duration=$(playerctl metadata --format "{{ mpris:length }}" 2>/dev/null || echo "1")
    
    # Convert to seconds and calculate progress (0-10 scale)
    local pos_sec=$((position / 1000000))
    local dur_sec=$((duration / 1000000))
    local progress=0
    
    if [[ $dur_sec -gt 0 ]]; then
        progress=$(( (pos_sec * 10) / dur_sec ))
    fi
    
    # Create progress bar with 10 segments
    local bar=""
    for i in {0..9}; do
        if [[ $i -lt $progress ]]; then
            bar+="▓"
        elif [[ $i -eq $progress ]]; then
            bar+="▒"
        else
            bar+="░"
        fi
    done
    
    # Rotating music symbols based on seconds
    local symbols=("♪" "♫" "♬" "♩")
    local symbol_index=$(( ($(date +%s) % 4) ))
    local left_symbol=${symbols[$symbol_index]}
    local right_symbol=${symbols[$(( (symbol_index + 2) % 4 ))]}
    
    # Show pause symbol if paused
    if [[ "$status" == "Paused" ]]; then
        echo "$left_symbol ⏸ $bar ⏸ $right_symbol"
    else
        echo "$left_symbol $bar $right_symbol"
    fi
}

get_track_info() {
    local status=$(get_music_status)
    
    if [[ "$status" != "Playing" && "$status" != "Paused" ]]; then
        echo ""
        return
    fi
    
    local artist=$(playerctl metadata --format "{{ artist }}" 2>/dev/null || echo "Unknown Artist")
    local title=$(playerctl metadata --format "{{ title }}" 2>/dev/null || echo "Unknown Track")
    
    # Limit length to prevent overflow
    local max_length=40
    local full_text="$artist - $title"
    
    if [[ ${#full_text} -gt $max_length ]]; then
        full_text="${full_text:0:$((max_length-3))}..."
    fi
    
    echo "$full_text"
}

get_time_status() {
    local status=$(get_music_status)
    
    if [[ "$status" != "Playing" && "$status" != "Paused" ]]; then
        echo ""
        return
    fi
    
    local position=$(playerctl metadata --format "{{ duration(position) }}" 2>/dev/null || echo "0:00")
    local duration=$(playerctl metadata --format "{{ duration(mpris:length) }}" 2>/dev/null || echo "0:00")
    
    # Add status symbol
    if [[ "$status" == "Paused" ]]; then
        echo "$position / $duration paused"
    else
        echo "$position / $duration playing..."
    fi
}

# Main execution based on argument
case "$1" in
    "bar")
        get_animated_bar
        ;;
    "track")
        get_track_info
        ;;
    "time")
        get_time_status
        ;;
    "artwork")
        get_album_artwork
        ;;
    *)
        echo "Usage: $0 {bar|track|time|artwork}"
        exit 1
        ;;
esac
