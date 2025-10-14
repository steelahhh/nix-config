{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.hypridle
    pkgs.hyprls
    pkgs.hyprlock
    pkgs.hyprpaper
    pkgs.hyprpanel
  ];

  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.enable = true;

  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config = {
      common.default = [ "gtk" ];
      hyprland.default = [
        "gtk"
        "hyprland"
      ];
    };

    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  services.displayManager.sddm = {
    enable = true;
    package = pkgs.kdePackages.sddm;
  };
}
