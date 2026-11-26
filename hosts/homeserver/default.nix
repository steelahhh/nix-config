{ pkgs, username, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./services.nix
    ./bookorbit.nix
    ./arr.nix
    ./usenet.nix
    ./soulseek.nix
    ./discovery.nix
    ./monitoring.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "homeserver";
  time.timeZone = "Europe/Oslo";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  # Lets `nixos-rebuild --target-host` deploy over SSH as sasha.
  nix.settings.trusted-users = [ "@wheel" ];

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # Same keys as github.com/steelahhh.keys
    openssh.authorizedKeys.keys = import ../ssh-keys.nix;
  };
  # Key-only SSH, so remote deploys can sudo without a password prompt.
  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  # Remote end of tide's rsync source (TIDE_SOURCE=homeserver:/srv/music on ignis).
  environment.systemPackages = [ pkgs.rsync ];

  services.qemuGuest.enable = true;
  services.tailscale.enable = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # Follows what is pushed to trunk; push before deploying or the nightly run reverts it.
  system.autoUpgrade = {
    enable = true;
    flake = "github:steelahhh/nix-config#homeserver";
  };
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };

  systemd.tmpfiles.rules = [
    "d /srv/music 0775 ${username} users -"
    "d /srv/books 0775 ${username} users -"
    "d /srv/backups 0755 root root -"
  ];

  system.stateVersion = "26.11";
}
