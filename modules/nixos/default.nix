{ pkgs, ... }:
{
  imports = [
    ../common
    ./cosmic.nix
    ./gaming.nix
    ./flatpak.nix
  ];

  fonts.packages = [
    pkgs.noto-fonts
  ];

  environment.systemPackages = with pkgs; [
    git
    unzip

    helium

    ghostty
    calibre

    nicotine-plus
    beets
    rhythmbox
    picard

    nwg-look

    catppuccin-cursors.mochaDark

    proton-vpn

    kdePackages.dolphin
    kdePackages.dolphin-plugins
    pavucontrol

    openrazer-daemon
    lenovo-legion
    linuxKernel.packages.linux_zen.lenovo-legion-module

    gparted

    qwen-code
  ];

  programs.zsh.enable = true;
  services.gvfs.enable = true;
}
