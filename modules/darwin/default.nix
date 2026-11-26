{
  imports = [
    ../common
    ./android.nix
    ./homebrew.nix
    ./swift.nix
  ];

  system.nvram.variables = {
    "SystemAudioVolume" = " ";
  };

  system.defaults = {
    loginwindow = {
      GuestEnabled = false;
      SHOWFULLNAME = false;
    };
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      AppleShowScrollBars = "WhenScrolling";
      ApplePressAndHoldEnabled = false;
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
    };
    trackpad = {
      ActuationStrength = 0;
      Clicking = true;
      FirstClickThreshold = 1;
      SecondClickThreshold = 1;
      TrackpadRightClick = true;
    };
    LaunchServices = {
      LSQuarantine = false;
    };
    dock = {
      "mouse-over-hilite-stack" = true;
      tilesize = 36;
      mineffect = "scale";
      "minimize-to-application" = true;
      "enable-spring-load-actions-on-all-items" = true;
      "show-process-indicators" = true;
      "expose-animation-duration" = 0.1;
      "mru-spaces" = false;
      "autohide-delay" = 0.0;
      "autohide-time-modifier" = 0.0;
      autohide = true;
      showhidden = true;
      "show-recents" = false;
    };
    CustomUserPreferences = {
      "com.apple.SoftwareUpdate" = {
        AutomaticCheckEnabled = true;
        ScheduleFrequency = 1;
        AutomaticDownload = 1;
        CriticalUpdateInstall = 1;
      };
      # Free ctrl+space (60) and ctrl+opt+space (61) from input-source switching
      "com.apple.symbolichotkeys".AppleSymbolicHotKeys = {
        "60" = {
          enabled = false;
          value = { parameters = [ 32 49 262144 ]; type = "standard"; };
        };
        "61" = {
          enabled = false;
          value = { parameters = [ 32 49 786432 ]; type = "standard"; };
        };
      };
    };
  };
}
