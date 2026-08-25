{ ... }:

{
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

  # Add Nix packages needed only in the VM here.
  home.packages = [ ];
}
