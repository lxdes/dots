#!/usr/bin/env sh

output=$(xrandr --query 2>/dev/null | awk '$1 == "DP-1" && $2 == "connected" { print $1; exit }')
[ -n "$output" ] || output=$(xrandr --query 2>/dev/null | awk '$2 == "connected" { print $1; exit }')
[ -n "$output" ] && xrandr --output "$output" --auto --primary
