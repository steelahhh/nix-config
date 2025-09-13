{ pkgs, ... }:
{
  home.packages = [
    pkgs.jetbrains-toolbox
    pkgs.zed-editor
    pkgs.git
    pkgs.zsh
  ];

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

  programs.git = {
    enable = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = pkgs.lib.importTOML ./common/starship/starship.toml;
  };

  home.file.".ideavimrc".source = ./common/idea.vimrc;
  home.file.".config/zed/settings.json".source = ./common/zed/settings.json;
  home.file.".config/zed/keymap.json".source = ./common/zed/keymap.json;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
  programs.home-manager.enable = true;
}
