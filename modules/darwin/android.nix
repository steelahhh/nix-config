{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.maestro
    pkgs.gnupg
    pkgs.claude-code
  ];
}
