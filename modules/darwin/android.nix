{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.maestro
  ];
}
