{ pkgs, ... }:

{
  home.packages = with pkgs; [
    brightnessctl
    pulseaudio
    xinput
  ];
}
