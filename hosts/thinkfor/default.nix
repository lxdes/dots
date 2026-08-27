{ ... }:

{
  home.username = "array";
  home.homeDirectory = "/home/array";

  imports = [
    ../../home.nix
    ../../modules/apps/bolt.nix
    ../../modules/apps/discord.nix
    ../../modules/apps/feishin.nix
    ../../modules/apps/localsend.nix
    ../../modules/apps/motrix.nix
    ../../modules/apps/protonplus.nix
    ../../modules/apps/signal.nix
    ../../modules/apps/onlyoffice.nix
    ../../modules/cli/bluetui.nix
    ../../modules/cli/herdr.nix
    ../../modules/cli/opencode.nix
    ../../modules/cli/vm-curator.nix
    ../../modules/cli/wiremix.nix
    ../../modules/editors/emacs.nix
    ../../modules/shells/zsh.nix
    ../../modules/system/audio.nix
    ../../modules/system/cursor.nix
    ../../modules/system/fonts.nix
    ../../modules/system/git.nix
    ../../modules/system/icons.nix
    ../../modules/system/quickshell.nix
    ../../modules/system/screenshot.nix
    ../../modules/terminals/wezterm.nix
  ];

  nux.cursor.size = 24;
  nux.xftDpi = 96;

  # Add Nix packages needed only on this host here.
  home.packages = [ ];
}
