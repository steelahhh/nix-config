{ pkgs, ... }:
{
  imports = [ ../common.nix ];

  # nix-darwin is silly so have to add JAVA_HOME manually
  programs.zsh = {
    initContent = "
export JAVA_HOME=${pkgs.jdk23}
    ";

    shellAliases = {
      nos = "nh darwin switch /Users/ignis/nix-config";
    };
  };

  home.file.".aerospace.toml".source = ./aerospace/aerospace.toml;
}
