#!/usr/bin/env sh

if [ -r "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi

export XDG_CURRENT_DESKTOP=bspwm
exec bspwm
