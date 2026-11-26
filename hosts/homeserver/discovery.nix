{ config, username, ... }:
let
  digarrEnv = config.age.secrets.digarr-env.path;
in
{
  age.secrets.digarr-env.file = ../../secrets/digarr-env.age;

  systemd.tmpfiles.rules = [
    "d /var/lib/digarr 0750 ${username} users -"
    "d /var/lib/digarr/data 0750 ${username} users -"
    "d /var/lib/digarr/backups 0750 ${username} users -"
  ];

  virtualisation.oci-containers.containers.digarr = {
    image = "docker.io/iuliandita/digarr:2.3.0";
    ports = [ "5000:3000" ];
    environment = {
      # Must exactly match the origin the browser uses (no trailing slash).
      ALLOWED_ORIGIN = "http://homeserver:5000";
      DIGARR_ALLOW_INSECURE_COOKIES = "true";
      TZ = config.time.timeZone;
    };
    environmentFiles = [ digarrEnv ];
    volumes = [
      "/var/lib/digarr/data:/app/data"
      "/var/lib/digarr/backups:/app/backups"
    ];
    extraOptions = [
      "--add-host=homeserver:host-gateway"
    ];
  };

  networking.firewall.allowedTCPPorts = [
    5000
  ];
}
