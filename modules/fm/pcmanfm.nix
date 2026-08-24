{
  config,
  lib,
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

  home.activation.pcmanfmBookmarks = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    bookmarks="${config.xdg.configHome}/gtk-3.0/bookmarks"
    if [[ -z "''${DRY_RUN_CMD:-}" ]]; then
      mkdir -p "$(dirname "$bookmarks")"
      touch "$bookmarks"
      while IFS= read -r bookmark; do
        ${pkgs.gnugrep}/bin/grep -Fqx "$bookmark" "$bookmarks" ||
          printf '%s\n' "$bookmark" >> "$bookmarks"
      done <<'EOF'
trash:/// Trash
file://${config.home.homeDirectory}/Desktop Desktop
file://${config.home.homeDirectory}/Documents Documents
file://${config.home.homeDirectory}/Downloads Downloads
file://${config.home.homeDirectory}/Music Music
file://${config.home.homeDirectory}/Pictures Pictures
file://${config.home.homeDirectory}/Videos Videos
EOF
    fi
  '';
}
