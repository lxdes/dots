#!/usr/bin/env bash

SCREENSHOT_DIR="${SCREENSHOT_DIR:-$HOME/Pictures/Screenshots}"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME="screenshot_${DATE}.png"
OUTPUT="${SCREENSHOT_DIR}/${FILENAME}"

mkdir -p "$SCREENSHOT_DIR"

# ── Rofi menu ────────────────────────────────────────────────────────────────
CHOICE=$(printf "Fullscreen\n  Region\n  Window" |
	rofi -dmenu \
		-i \
		-p "" \
		-theme-str 'window {width: 240px; height: 260px;}' \
		-no-custom)

case "$CHOICE" in
"Fullscreen")
	sleep 0.3
	maim -u "$OUTPUT"
	;;
"  Region")
	sleep 0.3
	maim -s -u "$OUTPUT"
	;;
"  Window")
	sleep 0.3
	maim -s -b 2 -c 0.3,0.6,1.0,1 -f png "$OUTPUT"
	;;
*)
	exit 0
	;;
esac

# ── Post-capture actions ─────────────────────────────────────────────────────
if [[ -f "$OUTPUT" ]]; then
	if command -v xclip &>/dev/null; then
		xclip -selection clipboard -target image/png -i "$OUTPUT"
		CLIP_MSG=" — copied to clipboard"
	fi

	if command -v notify-send &>/dev/null; then
		notify-send "Screenshot saved${CLIP_MSG:-}" "$OUTPUT" \
			--icon="$OUTPUT" \
			--expire-time=4000
	fi
fi
