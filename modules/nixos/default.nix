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
    unzip

    ghostty
    calibre

    nicotine-plus
    beets
    rhythmbox
    picard

    nwg-look

    catppuccin-cursors.mochaDark

    protonvpn-gui

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
