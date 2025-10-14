{ pkgs, ... }:
{
  imports = [
    ../common
    ./hyprland.nix
    ./gaming.nix
    ./flatpak.nix
  ];

  fonts.packages = [
    pkgs.noto-fonts
  ];

  environment.systemPackages = with pkgs; [
    git

    ghostty

    nwg-look

    catppuccin-cursors.mochaDark

    kdePackages.dolphin
    kdePackages.dolphin-plugins
    pavucontrol

    openrazer-daemon
    lenovo-legion
    linuxKernel.packages.linux_zen.lenovo-legion-module
  ];

  programs.zsh.enable = true;
  services.gvfs.enable = true;
}
