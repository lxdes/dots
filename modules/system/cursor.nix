{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.nux = {
    cursor = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Bibata-Modern-Ice";
        description = "Cursor theme used by the X11 session.";
      };

      size = lib.mkOption {
        type = lib.types.ints.positive;
        default = 24;
        description = "Cursor size used by the X11 session.";
      };
    };

    xftDpi = lib.mkOption {
      type = lib.types.ints.positive;
      default = 96;
      description = "Font DPI written to Xresources.";
    };
  };

  config = {
    home.pointerCursor = {
      enable = true;
      name = config.nux.cursor.name;
      package = pkgs.bibata-cursors;
      size = config.nux.cursor.size;
    };

    home.sessionVariables = {
      XCURSOR_SIZE = toString config.nux.cursor.size;
      XCURSOR_THEME = config.nux.cursor.name;
    };

    home.file.".Xresources".text = ''
      ! Fonts DPI
      Xft.antialias: 1
      Xft.hinting: 1
      Xft.hintstyle: hintslight
      Xft.rgba: rgb
      Xft.lcdfilter: lcddefault
      Xft.dpi: ${toString config.nux.xftDpi}

      ! Cursor
      Xcursor.size: ${toString config.nux.cursor.size}
      Xcursor.theme: ${config.nux.cursor.name}
    '';
  };
}
