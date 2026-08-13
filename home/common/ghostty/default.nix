{ ... }:
{
  # Ghostty itself is installed by Homebrew on darwin (see modules/darwin/homebrew.nix)
  # and as a system package on nixos, so only the config file is managed here.
  home.file.".config/ghostty/config".source = ./config;
}
