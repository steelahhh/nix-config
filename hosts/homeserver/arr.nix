# Music grabbing stack: Lidarr searches via Prowlarr and "downloads" through
# Decypharr, which poses as qBittorrent but hands torrents to TorBox (RealDebrid
# can be added in its wizard later). The torrenting happens at the debrid
# provider, so only Prowlarr's indexer traffic needs the VPN: it shares
# Gluetun's network namespace, which kills anything not going through Proton.
{ config, ... }:
let
  vpnEnv = config.age.secrets.protonvpn-env.path; # WIREGUARD_PRIVATE_KEY, WIREGUARD_ADDRESSES
in
{
  age.secrets.protonvpn-env.file = ../../secrets/protonvpn-env.age;

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
      # v3.41.x restart-loops on Proton: the tunnel passes traffic only after
      # the ~6s startup healthcheck window (ICMP blocked → MTU discovery slow).
      # https://github.com/qdm12/gluetun/issues/3069 — v3.40.0 is the fix.
      image = "docker.io/qmcgaw/gluetun:v3.40.0";
      environment = {
        VPN_SERVICE_PROVIDER = "protonvpn";
        VPN_TYPE = "wireguard";
        SERVER_COUNTRIES = "Lithuania,Latvia,Estonia";
        # Kill switch exceptions: LAN and Tailscale clients may reach the
        # Prowlarr UI, and Prowlarr may reach Lidarr on the host.
        FIREWALL_OUTBOUND_SUBNETS = "192.168.1.0/24,100.64.0.0/10";
        TZ = config.time.timeZone;
      };
      environmentFiles = [ vpnEnv ];
      ports = [ "9696:9696" ]; # Prowlarr UI, published through the VPN netns
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
    8282 # Decypharr
  ];
}
