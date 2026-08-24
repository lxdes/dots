#!/usr/bin/env sh

# Pad each option to center in ~20-char width
chosen=$(printf '%s\n' \
	"   Logout   " \
	"  Shutdown  " \
	"   Reboot   " \
	"    Lock    " \
	"  [Cancel]  " |
	rofi -dmenu -i -p "Power Menu" \
		-line-padding 4 \
		-hide-scrollbar \
		-theme-str 'window { width: 14%; anchor: center; location: center; }' \
		-no-fixed-num-lines)

# Trim leading/trailing spaces for matching
chosen=$(echo "$chosen" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

case "$chosen" in
Logout) bspc quit ;;
Shutdown) systemctl poweroff ;;
Reboot) systemctl reboot ;;
Lock) xsecurelock ;;
*) exit 0 ;;
esac
