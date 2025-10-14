{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.bottles.override { removeWarningPopup = true ; })
  ];

  programs.steam.enable = true;
}
