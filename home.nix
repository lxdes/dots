{
  config,
  pkgs,
  ...
}:

{
  nixpkgs.config.allowUnfree = true;

  home.stateVersion = "26.11";

  programs.home-manager.enable = true;
  home.enableNixpkgsReleaseCheck = false;

  targets.genericLinux.enable = true;

  imports = [
    ./home/default.nix
  ];

}
