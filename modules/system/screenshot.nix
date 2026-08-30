{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    imagemagick
    maim
    xclip
    jq
  ];

}
