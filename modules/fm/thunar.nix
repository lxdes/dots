{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    thunar
    thunar-volman
    thunar-archive-plugin
    thunar-shares-plugin
    thunar-media-tags-plugin
    engrampa
    p7zip
    unzip
    gvfs
  ];

}
