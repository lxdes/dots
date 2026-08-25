{ pkgs, ... }:

{
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
  };

  home.packages = with pkgs; [
    adw-gtk3
    orchis-theme
  ];
}
