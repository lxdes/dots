#!/usr/bin/env sh

export _JAVA_AWT_WM_NONREPARENTING=1

run() {
	pgrep -x "$1" >/dev/null || "$@" &
}

# --- Display ---
setup_display() {
	command -v xrandr >/dev/null 2>&1 || return 0

	layout="$HOME/nux/hosts/$(hostname -s)/displays.sh"
	[ -x "$layout" ] || layout="$HOME/nux/hosts/generic/displays.sh"
	if [ -x "$layout" ]; then
		for attempt in 1 2 3 4 5 6 7 8 9 10; do
			"$layout" && return 0
			sleep 1
		done
	fi

	output=
	attempt=
	for attempt in 1 2 3 4 5 6 7 8 9 10; do
		output=$(xrandr --query 2>/dev/null | awk '$1 == "DP-1" && $2 == "connected" { print $1; exit }')
		[ -n "$output" ] || output=$(xrandr --query 2>/dev/null | awk '$2 == "connected" { print $1; exit }')
		if [ -n "$output" ] && xrandr --output "$output" --auto --primary; then
			return 0
		fi
		sleep 1
	done
}

setup_display
(if [ -x "$HOME/.fehbg" ]; then "$HOME/.fehbg"; else set -- "$HOME/nux/wallpapers"/*; [ -f "$1" ] && feh --bg-fill "$1"; fi) &
run picom --config ~/.config/picom/picom.conf --vsync

# --- Core WM services ---
run sxhkd
run qs -n -c default

# --- System / session ---
run udiskie

# --- Apps ---
run emacs --daemon
