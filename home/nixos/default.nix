{ pkgs, config, ... }:
{
  imports = [
    ../common.nix
    ./theme.nix
    ./hyprlock.nix
    ./hyprpaper.nix
  ];

  home.packages = [
  ];

  # dedicated passphrase-less age key, same identity as macOS (secrets/secrets.nix)
  age.identityPaths = [ "${config.home.homeDirectory}/.config/age/keys.txt" ];
  age.secrets.listenbrainz-token.file = ../../secrets/listenbrainz-token.age;

  home.sessionVariables = {
    LISTENBRAINZ_TOKEN_FILE = config.age.secrets.listenbrainz-token.path;
    TIDE_SOURCE = "homeserver:/srv/music";
  };

  programs.rofi = {
    enable = true;
    theme = "Arc-Dark";
  };

  home.file.".config/beets/config.yaml".source = "${../common/beets.yaml}";
}
