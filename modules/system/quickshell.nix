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
    iproute2
    libnotify
    networkmanager
    pipewire
    procps
    tailscale
    wiremix
    xprop
    xset
  ];
}
