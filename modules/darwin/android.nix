{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.maestro
    pkgs.gnupg
  ];
}
