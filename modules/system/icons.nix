{ pkgs, ... }:

let
  windowCss = ''
    window,
    window.background,
    window.csd,
    window.solid-csd,
    decoration {
      border-radius: 2px;
    }
  '';
in
{
  gtk = {
    enable = true;
    gtk3.extraCss = windowCss;
    gtk3.extraConfig.gtk-decoration-layout = "";
    gtk4.extraCss = windowCss;
    gtk4.extraConfig.gtk-decoration-layout = "";
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
