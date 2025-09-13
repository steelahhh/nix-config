{ self, pkgs, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Enable Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Set the system's revision from the flake's git information
  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.primaryUser = "Ignis";

  system.stateVersion = 6;

  users.users.ignis = {
    shell = pkgs.zsh;
    home = "/Users/ignis";
  };

  home-manager.users.ignis = {
    imports = [ ../../home/darwin/default.nix ];
    home.stateVersion = "25.05";
    home.username = "ignis";
    home.homeDirectory = "/Users/ignis";
  };
}
