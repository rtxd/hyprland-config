#!/usr/bin/env bash

# Music widget script for hyprlock with animations
# Returns different components based on the argument passed

get_music_status() {
    playerctl status 2>/dev/null || echo "Stopped"
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
    *)
        echo "Usage: $0 {bar|track|time}"
        exit 1
        ;;
esac
