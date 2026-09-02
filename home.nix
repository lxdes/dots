{
  config,
  pkgs,
  hostProfile ? "generic",
  ...
}:

{
  nixpkgs.config.allowUnfree = true;

  home.stateVersion = "26.11";

  programs.home-manager.enable = true;
  home.enableNixpkgsReleaseCheck = false;
  home.sessionVariables.NUX_HOST = hostProfile;

  targets.genericLinux.enable = true;

  imports = [
    ./home/default.nix
    ./modules/terminals/st.nix
  ];

}
