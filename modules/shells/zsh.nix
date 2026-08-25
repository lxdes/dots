{
  config,
  pkgs,
  lib,
  ...
}:

let
  zsh = config.programs.zsh;
in

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "minimal";
    };
    syntaxHighlighting = {
      enable = true;
      highlighters = [
        "main"
        "brackets"
        "pattern"
        "regexp"
        "root"
        "line"
      ];
    };
    historySubstringSearch.enable = true;

    history = {
      ignoreDups = true;
      save = 10000;
      size = 10000;
    };

    initContent = ''
      setopt globdots
      setopt EXTENDED_GLOB

      export EDITOR="emacs"
      export VISUAL="emacs"

      export TERM=st

      autoload -Uz compinit
      if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]; then
        compinit
      else
        compinit -C
      fi

      # buffer / async settings
      export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
      export ZSH_AUTOSUGGEST_USE_ASYNC=1

      # Path additions
      export PATH="$HOME/.config/emacs/bin/:$PATH"
      export PATH="$HOME/.local/bin:$PATH"
      export PATH="$HOME/.cargo/bin/:$PATH"

      eval "$(zoxide init zsh)"
      fastfetch

    '';

    shellAliases = {
      em = "/usr/bin/emacs -nw";
      dsync = "doom sync && pkill emacs && emacs --daemon";
      cd = "z";
      dots = "z ~/nux";
      cat = "bat";
      home = "cd && cd nux && nix flake update && home-manager switch --flake .#forda";
      update = "sudo dnf upgrade --refresh && cd && cd nux && nix flake update && home-manager switch --flake .#forda";
      ls = "eza -A --color=always --group-directories-first --icons";
      ll = "eza -Ahl --color=always --group-directories-first --icons";
      lt = "eza -aT --color=always --group-directories-first";
      jctl = "journalctl -p 3 -xb";
      prefetch = "nix-prefetch-url --type sha256";
    };

  };

  home.packages = [
    pkgs.zoxide
    pkgs.eza
    pkgs.bat
  ];
}
