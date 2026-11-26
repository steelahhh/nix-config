{ config, username, ... }:
let
  slskdEnv = config.age.secrets.slskd-env.path;
in
{
  age.secrets.slskd-env.file = ../../secrets/slskd-env.age;

  services.slskd = {
    enable = true;
    user = username;
    group = "users";
    domain = null;
    environmentFile = slskdEnv;
    settings = {
      directories = {
        downloads = "/srv/downloads/slskd";
        incomplete = "/srv/downloads/slskd-incomplete";
      };
      shares.directories = [ "/srv/slskd-share" ];
      soulseek = {
        # AirVPN's fixed port forward (arr.nix opens it on the tunnel).
        listen_port = 4702;
      };
      web.port = 5030;
    };
  };
  systemd.services.slskd.vpnConfinement = {
    enable = true;
    vpnNamespace = "airvpn";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/soularr 0750 ${username} users -"
    "d /srv/downloads/slskd 0775 ${username} users -"
    "d /srv/downloads/slskd-incomplete 0775 ${username} users -"
    "d /srv/slskd-share 0775 ${username} users -"
  ];

  virtualisation.oci-containers.containers.soularr = {
    image = "docker.io/mrusse08/soularr:v1.2.3";
    ports = [ "8265:8265" ];
    environment = {
      SCRIPT_INTERVAL = "300";
      TZ = config.time.timeZone;
    };
    volumes = [
      "/var/lib/soularr:/data"
      "/srv/downloads/slskd:/srv/downloads/slskd"
    ];
    extraOptions = [
      "--add-host=homeserver:host-gateway"
      # Upstream uses --user, not PUID/PGID; sasha:users owns the dirs.
      "--user=1000:100"
    ];
  };

  networking.firewall.allowedTCPPorts = [
    8265
  ];
}
