{ config, ... }:

let
  dotfiles = "${config.home.homeDirectory}/nux/home/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

  configs = {
    doom = "doom";
    fastfetch = "fastfetch";
    bspwm = "bspwm";
    sxhkd = "sxhkd";
    picom = "picom";
    touchegg = "touchegg";
    wezterm = "wezterm";
    herdr = "herdr";
    quickshell = "quickshell";
  };

  homeConfigs = {
    ".xinitrc" = ".xinitrc";
    ".Xresources" = ".Xresources";
  };
in
{
  xdg.configFile = builtins.mapAttrs (name: subpath: {
    source = create_symlink "${dotfiles}/${subpath}";
    recursive = true;
  }) configs // {
    "systemd/user/bspwm-session.target".source =
      create_symlink "${dotfiles}/systemd/bspwm-session.target";
  };

  home.file = builtins.mapAttrs (name: subpath: {
    source = create_symlink "${dotfiles}/${subpath}";
    recursive = true;
  }) homeConfigs;
}
