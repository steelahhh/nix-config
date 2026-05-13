{ pkgs, config, ... }:
{
  imports = [ ../common.nix ];

  home.sessionVariables = {
    ANDROID_HOME = "${config.home.homeDirectory}/Library/Android/sdk";
    JAVA_HOME = "${pkgs.jdk21}";
  };

  programs.zsh = {
    initContent = ''
      unalias gg
      eval "$(zoxide init zsh)"
    '';

    shellAliases = {
      nos = "nh darwin switch /Users/ignis/nix-config";
    };
  };

  home.file.".aerospace.toml".source = ./aerospace/aerospace.toml;
}
