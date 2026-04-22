{ pkgs, ... }:
{
  imports = [
    ../common.nix
    ./theme.nix
    ./hyprlock.nix
    ./hyprpaper.nix
  ];

  home.packages = [
    pkgs.zed-editor
  ];

  programs.rofi = {
    enable = true;
    theme = "Arc-Dark";
  };

  home.file.".config/beets/config.yaml".source = "${../common/beets.yaml}";
}
