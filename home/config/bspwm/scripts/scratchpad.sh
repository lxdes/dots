#!/usr/bin/env sh
# scratchpad — toggle a class-tagged st window.
# Usage: scratchpad <name>

case "$1" in
terminal)
	GEOM="900x500+0+0"
	CMD=""
	;;
wiremix)
	GEOM="1200x700+0+0"
	CMD="wiremix"
	;;
bluetui)
	GEOM="2000x1200+0+0"
	CMD="bluetui"
	;;
nmtui)
	GEOM="2000x1000+0+0"
	CMD="nmtui"
	;;

*)
	echo "unknown scratchpad: $1" >&2
	exit 1
	;;
esac

CLASS="scratchpad-$1"
id=$(xdotool search --class "$CLASS" | head -n1)

if [ -z "$id" ]; then
	bspc rule -a "$CLASS" -o state=floating rectangle="$GEOM" center=on sticky=on
	if [ -n "$CMD" ]; then
		st -c "$CLASS" -e $CMD &
	else
		st -c "$CLASS" &
	fi
else
	bspc node "$id" -g hidden -f
fi
