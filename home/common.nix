{ pkgs, ... }:
{
  home.packages = [
    pkgs.jetbrains-toolbox
    pkgs.git
    pkgs.git-lfs
  ];

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  imports = [
    ./common/zed
    ./common/vim.nix
    ./common/shell.nix
    ./common/zellij.nix
  ];

  programs.git = {
    enable = true;
  };

  programs.home-manager.enable = true;
}
