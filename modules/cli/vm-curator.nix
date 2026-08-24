{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    vm-curator
  ];

}
