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

  age.identityPaths = [ "${config.home.homeDirectory}/.config/age/keys.txt" ];
  age.secrets.listenbrainz-token.file = ../../secrets/listenbrainz-token.age;

  # initContent (.zshrc), not sessionVariables: HM guards those with an
  # exported __HM_ZSH_SESS_VARS_SOURCED, so shells spawned from a pre-rebuild
  # parent (long-running zellij server, old panes) silently skip new vars.
  programs.zsh.initContent = ''
    export TIDE_SOURCE="homeserver:/srv/music"
    export LISTENBRAINZ_TOKEN_FILE="${config.age.secrets.listenbrainz-token.path}"
  '';

  programs.rofi = {
    enable = true;
    theme = "Arc-Dark";
  };

  home.file.".config/beets/config.yaml".source = "${../common/beets.yaml}";
}
