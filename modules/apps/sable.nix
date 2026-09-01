{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    sable
  ];
}
