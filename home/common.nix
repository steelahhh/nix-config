{ pkgs, ... }:
{
  home.packages = [
    pkgs.jetbrains-toolbox
    pkgs.git
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
