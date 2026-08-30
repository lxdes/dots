{
  config,
  pkgs,
  ...
}:

{
  home.packages = [
    pkgs.wezterm
  ];
}
