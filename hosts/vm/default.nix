{ ... }:

{
  home.username = "array";
  home.homeDirectory = "/home/array";

  imports = [
    ../../home.nix
    ../../modules/apps/editors/emacs.nix
    ../../modules/fm/pcmanfm.nix
    ../../modules/shells/zsh.nix
    ../../modules/system/audio.nix
    ../../modules/system/cursor.nix
    ../../modules/system/fonts.nix
    ../../modules/system/git.nix
    ../../modules/system/icons.nix
    ../../modules/system/quickshell.nix
    ../../modules/system/screenshot.nix
  ];

  nux.cursor.size = 24;
  nux.xftDpi = 96;

  # Add Nix packages needed only in the VM here.
  home.packages = [ ];
}
