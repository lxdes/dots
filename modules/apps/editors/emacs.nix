{ pkgs, ... }:

{
  programs.emacs = {
    enable = true;
    extraPackages = epkgs: [
      epkgs.treesit-grammars.with-all-grammars
      epkgs.pdf-tools

    ];
  };
  home.sessionVariables = {
    PKG_CONFIG_PATH = "$HOME/.nix-profile/lib/pkgconfig:$PKG_CONFIG_PATH";
  };
  home.packages = [
    pkgs.git
    pkgs.ripgrep
    pkgs.libtool
    pkgs.cmake
    pkgs.pkg-config
    pkgs.clang-tools
    pkgs.hunspell
    pkgs.hunspellDicts.en_AU
    pkgs.hunspellDicts.es_ES
    pkgs.hunspellDicts.en-gb-ise
    pkgs.gcc
    pkgs.gnumake
    pkgs.mpv
    pkgs.nodejs_24
    pkgs.nixfmt
    pkgs.prettier
    pkgs.fd
    pkgs.findutils
    pkgs.mlocate
    pkgs.lua
    pkgs.luarocks
    pkgs.stylua
    pkgs.shfmt
    pkgs.shellcheck
    pkgs.black
    pkgs.lua-language-server
    pkgs.nixd
    pkgs.python3Packages.python-lsp-server
    pkgs.python3Packages.grip
    pkgs.rustup
    pkgs.google-fonts
    pkgs.vips
    pkgs.luaPackages.dkjson
    pkgs.emacsPackages.qml-mode
  ];
}
