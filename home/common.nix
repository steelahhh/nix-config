{ pkgs, ... }:
{
  home.packages = [
    pkgs.jetbrains-toolbox
    pkgs.git
    pkgs.git-lfs
  ];

  imports = [
    ./common/zed
    ./common/vim.nix
    ./common/shell.nix
  ];

  programs.git = {
    enable = true;
  };

  programs.home-manager.enable = true;
}
