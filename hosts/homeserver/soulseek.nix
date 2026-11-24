# Soulseek acquisition for Lidarr: slskd runs in the airvpn namespace
# (arr.nix) so all P2P traffic rides the AirVPN tunnel; soularr bridges
# Lidarr's wanted list to slskd searches and imports completed downloads via
# Lidarr's API (no download client entry needed). AirVPN's fixed forwarded
# port lets peers connect in. Sharing is a dedicated folder
# (/srv/slskd-share), NOT the music library.
# See docs/navidrome-music-stack-plan.md.
{ config, username, ... }:
let
  # SLSKD_SLSK_USERNAME, SLSKD_SLSK_PASSWORD, SLSKD_API_KEY (Administrator
  # role by default — soularr needs write access), SLSKD_USERNAME, SLSKD_PASSWORD
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
    # slskd requires the download dirs to exist and be writable before startup.
    "d /srv/downloads/slskd 0775 ${username} users -"
    "d /srv/downloads/slskd-incomplete 0775 ${username} users -"
    # Dedicated Soulseek share — populated by hand, decoupled from /srv/music.
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
      # config.ini lives here; template: soularr-config.ini in this directory.
      "/var/lib/soularr:/data"
      "/srv/downloads/slskd:/srv/downloads/slskd"
    ];
    extraOptions = [
      # Only API calls (Lidarr :8686, slskd :5030 via the namespace's host
      # port mapping); P2P stays inside slskd/VPN. Resolve homeserver to the
      # host, not 127.0.0.2.
      "--add-host=homeserver:host-gateway"
      # Upstream uses --user, not PUID/PGID; sasha:users owns the dirs.
      "--user=1000:100"
    ];
  };

  networking.firewall.allowedTCPPorts = [
    8265 # soularr
  ];
}
