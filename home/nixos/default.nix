{ pkgs, ... }:
{
  imports = [
    ../common.nix
    ./theme.nix
    ./hyprlock.nix
    ./hyprpaper.nix
  ];

  programs.rofi = {
    enable = true;
    theme = "Arc-Dark";
  };
}
