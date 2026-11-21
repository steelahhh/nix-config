# Music grabbing stack: Lidarr searches via Prowlarr and "downloads" through
# Decypharr, which poses as qBittorrent but hands torrents to TorBox (RealDebrid
# can be added in its wizard later). The torrenting happens at the debrid
# provider, so indexer traffic (Prowlarr) and Soulseek P2P (slskd) ride the
# VPN: both share Gluetun's netns, which kills anything not going through IVPN.
# ddg-fetcher (BookOrbit's Anna's Archive solver) also joins this netns so AA
# sees an IVPN exit; BookOrbit itself stays direct.
{ config, ... }:
let
  vpnEnv = config.age.secrets.ivpn-env.path; # WIREGUARD_PRIVATE_KEY, WIREGUARD_ADDRESSES, WIREGUARD_PRESHARED_KEY
in
{
  age.secrets.ivpn-env.file = ../../secrets/ivpn-env.age;

  systemd.tmpfiles.rules = [
    "d /var/lib/gluetun 0700 root root -"
    "d /var/lib/prowlarr 0750 sasha users -"
    "d /var/lib/decypharr 0750 sasha users -"
    # Decypharr writes here, Lidarr imports into /srv/music; same path inside
    # and outside the container so no remote path mapping is needed in Lidarr.
    "d /srv/downloads 0775 sasha users -"
  ];

  virtualisation.oci-containers.containers = {
    gluetun = {
      # Keep v3.40.0: verified with IVPN 2026-11-15. (On Proton, v3.41.x
      # restart-looped: traffic only passed after the ~6s startup healthcheck
      # window — https://github.com/qdm12/gluetun/issues/3069.)
      image = "docker.io/qmcgaw/gluetun:v3.40.0";
      environment = {
        VPN_SERVICE_PROVIDER = "ivpn";
        VPN_TYPE = "wireguard";
        # IVPN has no Baltic servers; Nordic-adjacent pool chosen 2026-11-15.
        SERVER_COUNTRIES = "Sweden,Finland,Denmark,Poland";
        # Kill switch exceptions: LAN and Tailscale clients may reach the
        # Prowlarr UI, and Prowlarr may reach Lidarr on the host.
        FIREWALL_OUTBOUND_SUBNETS = "192.168.1.0/24,100.64.0.0/10";
        TZ = config.time.timeZone;
      };
      environmentFiles = [ vpnEnv ];
      # Prowlarr and slskd UIs publish through this netns; both join with
      # --network=container:gluetun. Torrent points and Soulseek stay on the
      # VPN; the AA solver runs direct by user choice 2026-11-15.
      ports = [
        "9696:9696" # Prowlarr
        "5030:5030" # slskd
      ];
      volumes = [ "/var/lib/gluetun:/gluetun" ];
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--device=/dev/net/tun"
      ];
    };

    prowlarr = {
      image = "docker.io/linuxserver/prowlarr:2.7.0";
      dependsOn = [ "gluetun" ];
      environment = {
        PUID = "1000";
        PGID = "100";
        TZ = config.time.timeZone;
      };
      volumes = [ "/var/lib/prowlarr:/config" ];
      # No ports here: they are published on gluetun, whose netns this shares.
      # podman rejects --add-host in a shared netns; reach host services
      # (Lidarr) as host.containers.internal instead of homeserver.
      extraOptions = [ "--network=container:gluetun" ];
    };

    decypharr = {
      image = "docker.io/cy01/blackhole:v2.7.2";
      ports = [ "8282:8282" ];
      environment = {
        PUID = "1000";
        PGID = "100";
        TZ = config.time.timeZone;
      };
      volumes = [
        "/var/lib/decypharr:/app"
        "/srv/downloads:/srv/downloads"
      ];
      # Upstream requirements for its FUSE mounts; apparmor is not enabled on
      # NixOS, so no apparmor unconfined opt is needed.
      extraOptions = [
        # NixOS maps the hostname to 127.0.0.2 in /etc/hosts and podman copies
        # that into the container; resolve it to the host instead (Lidarr).
        "--add-host=homeserver:host-gateway"
        "--device=/dev/fuse"
        "--cap-add=SYS_ADMIN"
      ];
    };
  };

  services.lidarr = {
    enable = true;
    # Matches /srv ownership and Decypharr's PUID/PGID so imports just work.
    user = "sasha";
    group = "users";
    openFirewall = true;
  };

  networking.firewall.allowedTCPPorts = [
    9696 # Prowlarr (via gluetun)
    5030 # slskd (via gluetun)
    8282 # Decypharr
  ];
}
