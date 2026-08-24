{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    protonplus
  ];

}
