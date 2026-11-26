{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.maestro
    pkgs.gnupg
    pkgs.claude-code
  ];

  launchd.user.envVariables.JAVA_HOME = "${pkgs.jdk21}";
}
