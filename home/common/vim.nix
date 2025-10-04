{ ... }:
{
  home.file.".ideavimrc".source = ./idea.vimrc;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}
