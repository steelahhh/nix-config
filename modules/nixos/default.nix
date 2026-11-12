{ pkgs, inputs, ... }:
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

    # nixpkgs lags behind; Qwen subscription sign-in needs >= 0.26.8
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.qwen-code
  ];

  nix.settings = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  programs.zsh.enable = true;
  services.gvfs.enable = true;
}
