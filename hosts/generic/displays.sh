#!/usr/bin/env sh

output=$(xrandr --query | awk '$2 == "connected" { print $1; exit }')
[ -n "$output" ] || exit 1

xrandr --output "$output" --auto --primary
