{
  pkgs,
  ...
}:

let
  pcmanfmWithGvfs = pkgs.pcmanfm.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.gvfs ];
  });
in
{
  home.packages = with pkgs; [
    pcmanfmWithGvfs
    gvfs
    lxmenu-data
    p7zip
    shared-mime-info
    unzip
    engrampa
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "pcmanfm.desktop" ];
      "application/x-gnome-saved-search" = [ "pcmanfm.desktop" ];
    };
  };

}
