{ pkgs, ... }:
{
  home.packages = [
    pkgs.zsh
  ];

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = pkgs.lib.importTOML ./starship/starship.toml;
  };

  programs.zsh = {
    enable = true;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "amuse";
      plugins = [
        "git"
        "fzf"
      ];
    };
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = false;
    enableZshIntegration = true;
    defaultOptions = [
      "--no-mouse"
    ];
  };
}
