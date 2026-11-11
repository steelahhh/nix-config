{ ... }:
{
  imports = [ ./hardware-configuration.nix ];

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

  users.users.sasha = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # Same keys as github.com/steelahhh.keys
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGH96Nm9Nbb3h+4ru6VvBppcEn1FEuCc2glfFLNFdM6h"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIRy3sJUMmIVA83EOEajGPgx6qe4+0r3Qt2CecFjGS35"
    ];
  };
  # Key-only SSH, so remote deploys can sudo without a password prompt.
  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
  };

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
    "d /srv/music 0775 sasha users -"
    "d /srv/books 0775 sasha users -"
    "d /srv/backups 0755 root root -"
  ];

  system.stateVersion = "26.11";
}
