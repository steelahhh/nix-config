{ pkgs, username, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "ignis";
    networkmanager.enable = true;
  };

  time.timeZone = "Europe/Oslo";

  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "nb_NO.UTF-8";
    LC_IDENTIFICATION = "nb_NO.UTF-8";
    LC_MEASUREMENT = "nb_NO.UTF-8";
    LC_MONETARY = "nb_NO.UTF-8";
    LC_NAME = "nb_NO.UTF-8";
    LC_NUMERIC = "nb_NO.UTF-8";
    LC_PAPER = "nb_NO.UTF-8";
    LC_TELEPHONE = "nb_NO.UTF-8";
    LC_TIME = "nb_NO.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.tailscale.enable = true;

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];

  users.users.${username} = {
    isNormalUser = true;
    description = username;
    openssh.authorizedKeys.keys = import ../ssh-keys.nix;
    extraGroups = [
      "networkmanager"
      "wheel"
      "openrazer"
    ];
    shell = pkgs.zsh;
  };

  home-manager.users.${username} = {
    imports = [ ../../home/nixos/default.nix ];
    home.stateVersion = "25.05";
    home.username = username;
  };

  system.stateVersion = "25.05";
}
