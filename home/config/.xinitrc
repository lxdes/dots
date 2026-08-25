#!/usr/bin/env sh

if [ -r "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi

export XDG_CURRENT_DESKTOP=bspwm
dbus-update-activation-environment --systemd DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP
systemctl --user start bspwm-session.target

bspwm

systemctl --user stop bspwm-session.target
