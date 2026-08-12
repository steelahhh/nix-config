{ pkgs, config, ... }:
{
  imports = [ ../common.nix ];

  home.sessionVariables = {
    ANDROID_HOME = "${config.home.homeDirectory}/Library/Android/sdk";
    JAVA_HOME = "${pkgs.jdk21}";
  };

  programs.zsh = {
    initContent = ''
      # Homebrew is installed/managed by modules/darwin/homebrew.nix.
      # shellenv sets PATH, MANPATH, INFOPATH and HOMEBREW_*.
      # In .zshrc rather than .zprofile: zellij spawns a non-login zsh.
      if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv zsh)"
      fi

      unalias gg
      eval "$(zoxide init zsh)"
    '';

    shellAliases = {
      nos = "nh darwin switch /Users/ignis/nix-config";
    };
  };

  home.file.".aerospace.toml".source = ./aerospace/aerospace.toml;
}
