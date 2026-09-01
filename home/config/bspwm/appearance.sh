#!/usr/bin/env sh
#
# Dynamically scale bspwm borders, gaps, and top padding based on display DPI / resolution.
#

# 1. Determine DPI / Scale Factor
dpi=$(xrdb -get Xft.dpi 2>/dev/null)
if [ -z "$dpi" ] || [ "$dpi" -le 0 ] 2>/dev/null; then
	# Fallback: check screen height via xrandr
	res_h=$(xrandr --current 2>/dev/null | awk '/\*/ { split($1, a, "x"); print a[2]; exit }')
	if [ "${res_h:-1080}" -ge 2000 ]; then
		scale=2.0
	elif [ "${res_h:-1080}" -ge 1400 ]; then
		scale=1.5
	else
		scale=1.0
	fi
else
	# Scale relative to baseline 96 DPI
	scale=$(awk "BEGIN { s = $dpi / 96; if (s < 1) s = 1; printf \"%.2f\", s }")
fi

# 2. Compute scaled values
border_width=$(awk "BEGIN { printf \"%d\", ($scale * 2) + 0.5 }")
window_gap=$(awk "BEGIN { printf \"%d\", ($scale * 6) + 0.5 }")
top_padding=$(awk "BEGIN { printf \"%d\", ($scale * 32) + 0.5 }")

# 3. Apply to bspwm
bspc config border_width "$border_width"
bspc config window_gap "$window_gap"
bspc config top_padding "$top_padding"
