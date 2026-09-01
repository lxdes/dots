#!/usr/bin/env sh
#
# Dynamically scale bspwm borders, gaps, and top padding based on display DPI / resolution.
#

# 1. Determine DPI / Scale Factor
dpi=$(xrdb -get Xft.dpi 2>/dev/null)
res_h=$(xrandr --current 2>/dev/null | awk -F'current ' '/Screen 0:/ { split($2, a, ","); split(a[1], dims, " x "); print dims[2] }')

if [ -n "$dpi" ] && [ "$dpi" -ge 192 ] 2>/dev/null; then
	scale=2.0
elif [ -n "$dpi" ] && [ "$dpi" -ge 144 ] 2>/dev/null; then
	scale=1.5
elif [ -n "$res_h" ] && [ "$res_h" -ge 2000 ] 2>/dev/null; then
	scale=2.0
elif [ -n "$res_h" ] && [ "$res_h" -ge 1400 ] 2>/dev/null; then
	scale=1.5
elif [ -n "$dpi" ] && [ "$dpi" -gt 0 ] 2>/dev/null; then
	scale=$(awk "BEGIN { s = $dpi / 96; if (s < 1) s = 1; printf \"%.2f\", s }")
else
	scale=1.0
fi

# 2. Compute scaled values
border_width=$(awk "BEGIN { printf \"%d\", ($scale * 2) + 0.5 }")
window_gap=$(awk "BEGIN { printf \"%d\", ($scale * 6) + 0.5 }")
top_padding=$(awk "BEGIN { printf \"%d\", ($scale * 32) + 0.5 }")

# 3. Apply to bspwm globally and per monitor
bspc config border_width "$border_width"
bspc config window_gap "$window_gap"
bspc config top_padding "$top_padding"

for mon in $(bspc query -M --names 2>/dev/null); do
	bspc config -m "$mon" top_padding "$top_padding"
	bspc config -m "$mon" window_gap "$window_gap"
done
