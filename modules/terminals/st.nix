{ pkgs, ... }:

let
  array-st = pkgs.stdenv.mkDerivation {
    pname = "array-st";
    version = "0.9.2";
    src = ../../home/config/st;

    nativeBuildInputs = [
      pkgs.ncurses
      pkgs.pkg-config
    ];

    buildInputs = [
      pkgs.fontconfig
      pkgs.freetype
      pkgs.libx11
      pkgs.libxft
      pkgs.libxrender
    ];

    installPhase = ''
      runHook preInstall

      install -Dm755 st "$out/bin/st"
      install -Dm755 st-urlhandler "$out/bin/st-urlhandler"
      install -Dm644 st.1 "$out/share/man/man1/st.1"
      substituteInPlace "$out/share/man/man1/st.1" \
        --replace-fail VERSION 0.9.2
      mkdir -p "$out/share/terminfo"
      tic -sx -o "$out/share/terminfo" st.info

      runHook postInstall
    '';

    meta = {
      description = "array's patched simple terminal build";
      homepage = "https://st.suckless.org/";
      license = pkgs.lib.licenses.mit;
      mainProgram = "st";
      platforms = pkgs.lib.platforms.linux;
    };
  };
in
{
  home.packages = [
    array-st
    pkgs.xclip
    pkgs.xdg-utils
  ];
}
