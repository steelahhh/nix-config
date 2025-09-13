{ pkgs, ... }:
{
  imports = [ ../common/default.nix ];

  environment.systemPackages = [
    pkgs.swiftlint
    pkgs.swiftformat
  ];

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
    global.autoUpdate = true;

    brews = [
      "mas"
      "cocoapods"
      "swiftgen"
    ];
    taps = [
      #"FelixKratz/formulae" #sketchybar
    ];
    casks = [
      "aerospace"
      "ghostty"
      "marta"
      "openmtp"
      "slack"
      "zen"
    ];
    masApps = {
      "NepTunes" = 1006739057;
      "Amphetamine" = 937984704;
      "Keynote" = 409183694;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Irvue" = 1039633667;
      "Ghostery" = 6504861501;
      "Proton Pass for Safari" = 6502835663;
    };
  };
}
