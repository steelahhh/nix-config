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
      # silent clicking = 0, default = 1
      ActuationStrength = 0;
      # enable tap to click
      Clicking = true;
      # firmness level, 0 = lightest, 2 = heaviest
      FirstClickThreshold = 1;
      # firmness level for force touch
      SecondClickThreshold = 1;
      # don't allow positional right click
      TrackpadRightClick = false;
    };
    LaunchServices = {
      LSQuarantine = false;
    };
    dock = {
      # Enable highlight hover effect for the grid view of a stack
      "mouse-over-hilite-stack" = true;
      # Set the icon size of Dock items to 36 pixels
      tilesize = 36;
      # Change minimize/maximize window effect
      mineffect = "scale";
      # Minimize windows into their application’s icon
      "minimize-to-application" = true;
      # Enable spring loading for all Dock items
      "enable-spring-load-actions-on-all-items" = true;
      # Show indicator lights for open applications
      "show-process-indicators" = true;
      # Speed up Mission Control animations
      "expose-animation-duration" = 0.1;
      # Don’t show Dashboard as a Space
      "dashboard-in-overlay" = true;
      # Don’t automatically rearrange Spaces based on most recent use
      "mru-spaces" = false;
      # Remove the auto-hiding Dock delay
      "autohide-delay" = 0.0;
      # Remove the animation when hiding/showing the Dock
      "autohide-time-modifier" = 0.0;
      # Automatically hide and show the Dock
      autohide = true;
      # Make Dock icons of hidden applications translucent
      showhidden = true;
      # Don’t show recent applications in Dock
      "show-recents" = false;
    };
    CustomUserPreferences = {
      "com.apple.SoftwareUpdate" = {
        AutomaticCheckEnabled = true;
        # Check for software updates daily, not just once per week
        ScheduleFrequency = 1;
        # Download newly available updates in background
        AutomaticDownload = 1;
        # Install System data files & security updates
        CriticalUpdateInstall = 1;
      };
    };
  };
}
