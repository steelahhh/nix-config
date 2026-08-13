{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.maestro
    pkgs.gnupg
    pkgs.claude-code
  ];

  # GUI apps (Android Studio via Dock/Toolbox) inherit launchd's environment,
  # not zsh's, so home.sessionVariables in home/darwin/default.nix is invisible
  # to them. Keep this in sync with that JAVA_HOME.
  launchd.user.envVariables.JAVA_HOME = "${pkgs.jdk21}";
}
