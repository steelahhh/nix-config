# digarr: music discovery with an approval queue feeding Lidarr (and
# optionally slskd directly). All connections (Lidarr / ListenBrainz / slskd / AI)
# are configured in its web UI and stored encrypted in the embedded PGlite
# database, so the encryption key is the only secret here. The container runs
# as uid 1000 (bun), matching sasha's uid for the bind mounts.
{ config, ... }:
let
  # DIGARR_ENCRYPTION_KEY (+ optional DIGARR_INITIAL_USERNAME/PASSWORD)
  digarrEnv = config.age.secrets.digarr-env.path;
in
{
  age.secrets.digarr-env.file = ../../secrets/digarr-env.age;

  systemd.tmpfiles.rules = [
    "d /var/lib/digarr 0750 sasha users -"
    "d /var/lib/digarr/data 0750 sasha users -"
    "d /var/lib/digarr/backups 0750 sasha users -"
  ];

  virtualisation.oci-containers.containers.digarr = {
    image = "docker.io/iuliandita/digarr:2.3.0";
    # Container listens on 3000; 3000 on the host is kept free for AdGuard Home.
    ports = [ "5000:3000" ];
    environment = {
      # Must exactly match the origin the browser uses (no trailing slash).
      ALLOWED_ORIGIN = "http://homeserver:5000";
      # Plain-HTTP LAN access; no TLS termination in front.
      DIGARR_ALLOW_INSECURE_COOKIES = "true";
      TZ = config.time.timeZone;
    };
    environmentFiles = [ digarrEnv ];
    volumes = [
      "/var/lib/digarr/data:/app/data"
      "/var/lib/digarr/backups:/app/backups"
    ];
    extraOptions = [
      # Reaches Lidarr/slskd on host-published ports; homeserver would
      # otherwise resolve to the container's own loopback (127.0.0.2).
      "--add-host=homeserver:host-gateway"
    ];
  };

  networking.firewall.allowedTCPPorts = [
    5000 # digarr
  ];
}
