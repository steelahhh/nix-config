{ pkgs, config, ... }:
{
  environment.systemPackages = [
    pkgs.maestro
    pkgs.gnupg
    pkgs.claude-code
  ];

  launchd.user.envVariables.JAVA_HOME = config.home-manager.users.ignis.home.sessionVariables.JAVA_HOME;
}
