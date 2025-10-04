{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.swiftlint
    pkgs.swiftformat
  ];
}
