# Soulseek acquisition for Lidarr: slskd shares gluetun's netns so all P2P
# traffic rides the IVPN tunnel; soularr bridges Lidarr's wanted list to slskd
# searches and imports completed downloads via Lidarr's API (no download
# client entry needed). IVPN has no port forwarding (removed 2023), so slskd
# is download-only: the share mount and listen port are configured, but peers
# cannot connect in. See docs/navidrome-music-stack-plan.md.
{ config, ... }:
let
  # SLSKD_SLSK_USERNAME, SLSKD_SLSK_PASSWORD, SLSKD_API_KEY (Administrator
  # role by default — soularr needs write access), SLSKD_USERNAME, SLSKD_PASSWORD
  slskdEnv = config.age.secrets.slskd-env.path;
in
{
  age.secrets.slskd-env.file = ../../secrets/slskd-env.age;

  systemd.tmpfiles.rules = [
    "d /var/lib/slskd 0750 sasha users -"
    "d /var/lib/soularr 0750 sasha users -"
    # /srv/downloads itself is created by arr.nix; slskd requires the
    # download dirs to exist and be writable before startup.
    "d /srv/downloads/slskd 0775 sasha users -"
    "d /srv/downloads/slskd-incomplete 0775 sasha users -"
  ];

  virtualisation.oci-containers.containers = {
    slskd = {
      image = "docker.io/slskd/slskd:0.26.2";
      dependsOn = [ "gluetun" ];
      environment = {
        PUID = "1000";
        PGID = "100";
        TZ = config.time.timeZone;
        SLSKD_SHARED_DIR = "/srv/music";
        SLSKD_DOWNLOADS_DIR = "/srv/downloads/slskd";
        SLSKD_INCOMPLETE_DIR = "/srv/downloads/slskd-incomplete";
        # Fixed: IVPN forwards no ports, so nothing inbound reaches it anyway.
        SLSKD_SLSK_LISTEN_PORT = "50300";
      };
      environmentFiles = [ slskdEnv ];
      volumes = [
        "/var/lib/slskd:/app"
        # Share back (inactive while download-only); read-only is enough.
        "/srv/music:/srv/music:ro"
        # Same path inside and outside: soularr and native Lidarr import from
        # the identical path slskd reports, so no remote path mapping.
        "/srv/downloads/slskd:/srv/downloads/slskd"
        "/srv/downloads/slskd-incomplete:/srv/downloads/slskd-incomplete"
      ];
      # Web UI port 5030 is published on gluetun (see arr.nix).
      extraOptions = [ "--network=container:gluetun" ];
    };

    soularr = {
      image = "docker.io/mrusse08/soularr:v1.2.3";
      ports = [ "8265:8265" ];
      environment = {
        SCRIPT_INTERVAL = "300";
        TZ = config.time.timeZone;
      };
      volumes = [
        # config.ini lives here; template: soularr-config.ini in this directory.
        "/var/lib/soularr:/data"
        "/srv/downloads/slskd:/srv/downloads/slskd"
      ];
      extraOptions = [
        # Only API calls (Lidarr :8686, slskd :5030 via host-published ports);
        # P2P stays inside slskd/VPN. Resolve homeserver to the host, not 127.0.0.2.
        "--add-host=homeserver:host-gateway"
        # Upstream uses --user, not PUID/PGID; sasha:users owns the dirs.
        "--user=1000:100"
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [
    8265 # soularr
  ];
}
