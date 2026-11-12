{ pkgs, ... }:
{
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic = {
    enable = true;
    xwayland.enable = true;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  xdg.portal.xdgOpenUsePortal = true;
  services.system76-scheduler.enable = true;
}