#!/usr/bin/env sh

window_id=$1
class=$2
instance=$3

app_id=$(xprop -id "$window_id" _GTK_APPLICATION_ID 2>/dev/null)
name=$(xprop -id "$window_id" WM_NAME 2>/dev/null)

if [ "$class" = "org.quickshell" ] || [ "$class" = "quickshell" ] || [ "$class" = "qs" ] || \
   [ "$instance" = "quickshell" ] || [ "$instance" = "org.quickshell" ] || [ "$instance" = "qs" ] || \
   echo "$app_id" | grep -q "org.quickshell" || echo "$name" | grep -qE "Launcher|Settings|Wallpaper Viewer"; then
    printf '%s\n' 'border=off state=floating focus=on'
    exit 0
fi

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
