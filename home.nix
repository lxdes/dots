{
  config,
  pkgs,
  ...
}:

{
  home.username = "array";
  home.homeDirectory = "/home/array";

  home.stateVersion = "26.11";

  programs.home-manager.enable = true;
  home.enableNixpkgsReleaseCheck = false;

  home.packages = [ pkgs.bsp-layout ];

  targets.genericLinux.enable = true;

  imports = [
    ./home/default.nix
    ./modules/default.nix
  ];

}
