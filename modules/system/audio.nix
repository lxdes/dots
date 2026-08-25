{ pkgs, ... }:

let
  cpupower = "${pkgs.linuxPackages.cpupower}/bin/cpupower";
  powerProfile = pkgs.writeShellScriptBin "nux-power-profile" ''
    set -eu

    case "''${1:-}" in
      performance)
        ${cpupower} -c all frequency-set -g performance
        ${cpupower} -c all set -e performance
        ${cpupower} set --boost 1
        ;;
      balanced)
        ${cpupower} -c all frequency-set -g powersave
        ${cpupower} -c all set -e balance_performance
        ${cpupower} set --boost 1
        ;;
      power-saver)
        ${cpupower} -c all frequency-set -g powersave
        ${cpupower} -c all set -e power
        ${cpupower} set --boost 0
        ;;
      *)
        printf 'Usage: nux-power-profile performance|balanced|power-saver\n' >&2
        exit 2
        ;;
    esac
  '';
in
{
  home.packages = with pkgs; [
    brightnessctl
    copyq
    curl
    jq
    lm_sensors
    pulseaudio
    powerProfile
    xinput
    xdotool
  ];
}
