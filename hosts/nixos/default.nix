{ config, pkgs, ... }:
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

  hardware.opengl.enable = true;
  hardware.openrazer.enable = true;
  hardware.nvidia = {
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    powerManagement.enable = true;
    modesetting.enable = true;
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

  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

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

  users.users.sasha = {
    isNormalUser = true;
    description = "sasha";
    extraGroups = [
      "networkmanager"
      "wheel"
      "openrazer"
    ];
    shell = pkgs.zsh;
  };

  home-manager.users.sasha = {
    imports = [ ../../home/nixos/default.nix ];
    home.stateVersion = "25.05";
    home.username = "sasha";
  };

  system.stateVersion = "25.05";
}
