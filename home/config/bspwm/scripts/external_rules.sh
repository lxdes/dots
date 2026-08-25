#!/usr/bin/env sh

window_id=$1
class=$2
instance=$3

case "$class:$instance" in
    Steam:steam|Steam:Steam|steam:steam|steam:Steam)
        title=$(xprop -id "$window_id" _NET_WM_NAME 2>/dev/null)
        title=${title#*= }
        title=${title#\"}
        title=${title%\"}

        # Keep the main client tiled; Steam's secondary UI uses the same class.
        if [ -n "$title" ] && [ "$title" != "Steam" ]; then
            printf '%s\n' 'state=floating center=on'
        fi
        ;;
esac
