{
  config,
  pkgs,
  ...
}:

{
  nixpkgs.config.allowUnfree = true;

  home.username = "array";
  home.homeDirectory = "/home/array";

  home.stateVersion = "26.11";

  programs.home-manager.enable = true;
  home.enableNixpkgsReleaseCheck = false;

  home.packages = [
    pkgs.vm-curator
  ];

  targets.genericLinux.enable = true;

  imports = [
    ./home/default.nix
    ./modules/default.nix
  ];

}
