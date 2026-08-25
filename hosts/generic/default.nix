{ ... }:

{
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  imports = [
    ../../home.nix
    ../../modules/editors/emacs.nix
    ../../modules/fm/pcmanfm.nix
    ../../modules/shells/zsh.nix
    ../../modules/system/audio.nix
    ../../modules/system/cursor.nix
    ../../modules/system/fonts.nix
    ../../modules/system/git.nix
    ../../modules/system/icons.nix
    ../../modules/system/screenshot.nix
  ];

  nux.cursor.size = 24;
  nux.xftDpi = 96;

  # Add Nix packages needed only on generic hosts here.
  home.packages = [ ];
}
