{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (python3.withPackages (
      pythonPackages: with pythonPackages; [
        icalendar
        python-dateutil
      ]
    ))
    bluez
    bsp-layout
    bluetui
    curl
    feh
    glib
    imagemagick
    iproute2
    jq
    libnotify
    maim
    networkmanager
    pipewire
    procps
    tailscale
    wiremix
    xclip
    xprop
    xset
  ];
}
