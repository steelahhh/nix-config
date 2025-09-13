{ pkgs, ... }:
{
  imports = [ ../common/default.nix ];

  environment.systemPackages = with pkgs; [
    git
    openrazer-daemon
    vivaldi
  ];

  programs.zsh.enable = true;

}
