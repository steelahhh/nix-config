# Music grabbing stack: Lidarr searches via Prowlarr and "downloads" through
# Decypharr, which poses as qBittorrent but hands torrents to TorBox (RealDebrid
# can be added in its wizard later). The torrenting happens at the debrid
# provider, so indexer traffic (Prowlarr) and Soulseek P2P (slskd) ride the
# VPN: both share Gluetun's netns, which kills anything not going through
# Proton. ddg-fetcher (BookOrbit's Anna's Archive solver) runs direct.
{ config, username, ... }:
let
  vpnEnv = config.age.secrets.protonvpn-env.path; # WIREGUARD_PRIVATE_KEY, WIREGUARD_ADDRESSES
  # gluetun's port-forwarding up-command PATCHes slskd with the forwarded
  # port and needs SLSKD_API_KEY; gluetun ignores the other slskd vars.
  slskdEnv = config.age.secrets.slskd-env.path;
in
{
  age.secrets.protonvpn-env.file = ../../secrets/protonvpn-env.age;

  systemd.tmpfiles.rules = [
    "d /var/lib/gluetun 0700 root root -"
    "d /var/lib/prowlarr 0750 ${username} users -"
    "d /var/lib/decypharr 0750 ${username} users -"
    # Decypharr writes here, Lidarr imports into /srv/music; same path inside
    # and outside the container so no remote path mapping is needed in Lidarr.
    "d /srv/downloads 0775 ${username} users -"
  ];

  virtualisation.oci-containers.containers = {
    gluetun = {
      # Keep v3.40.0: fixes the Proton healthcheck restart loop (v3.41.x only
      # passed traffic after the ~6s startup window —
      # https://github.com/qdm12/gluetun/issues/3069).
      image = "docker.io/qmcgaw/gluetun:v3.40.0";
      environment = {
        VPN_SERVICE_PROVIDER = "protonvpn";
        VPN_TYPE = "wireguard";
        # Baltic pool (user preference). With port forwarding on, Proton
        # auto-filters to PF-capable P2P servers (PORT_FORWARD_ONLY defaults
        # to true) — no need to set it.
        SERVER_COUNTRIES = "Lithuania,Latvia,Estonia";
        # Proton assigns a random forwarded port; slskd must listen on it for
        # Soulseek peers to connect in (sharing). The up-command PATCHes
        # slskd's runtime options — same netns, hence 127.0.0.1:5030. v3.40.0
        # only substitutes {{PORTS}} (one port for Proton). slskd's overlay is
        # volatile across its restarts and it may still be starting when this
        # fires, so retry on connection refused.
        VPN_PORT_FORWARDING = "on";
        VPN_PORT_FORWARDING_UP_COMMAND = ''/bin/sh -c 'wget -q -O /dev/null --timeout=5 --tries=12 --waitretry=2 --retry-connrefused --method=PATCH --header="Content-Type: application/json" --header="X-API-Key: $SLSKD_API_KEY" --body-data="{\"soulseek\":{\"listenPort\":{{PORTS}}}}" http://127.0.0.1:5030/api/v0/options' '';
        # Kill switch exceptions: LAN and Tailscale clients may reach the
        # Prowlarr UI, and Prowlarr may reach Lidarr on the host.
        FIREWALL_OUTBOUND_SUBNETS = "192.168.1.0/24,100.64.0.0/10";
        TZ = config.time.timeZone;
      };
      environmentFiles = [ vpnEnv slskdEnv ];
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
    user = username;
    group = "users";
    openFirewall = true;
  };

  networking.firewall.allowedTCPPorts = [
    9696 # Prowlarr (via gluetun)
    5030 # slskd (via gluetun)
    8282 # Decypharr
  ];
}
