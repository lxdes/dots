{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./xcolor.nix
    ./xsecurelock.nix
  ];
}
