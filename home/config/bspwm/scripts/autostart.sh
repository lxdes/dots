#!/usr/bin/env sh

export _JAVA_AWT_WM_NONREPARENTING=1

run() {
	pgrep -x "$1" >/dev/null || "$@" &
}

# --- Display ---
run xrandr --output DP-1 --mode 1920x1080 --rate 239.76
[ -x "$HOME/.config/bspwm/display-layout.sh" ] && "$HOME/.config/bspwm/display-layout.sh"
(if [ -x "$HOME/.fehbg" ]; then "$HOME/.fehbg"; else set -- "$HOME/nux/wallpapers"/*; [ -f "$1" ] && feh --bg-fill "$1"; fi) &
run picom --config ~/.config/picom/picom.conf --vsync

# --- Core WM services ---
run sxhkd
run qs -n -c default

# --- System / session ---
run udiskie

# --- Apps ---
run emacs --daemon
