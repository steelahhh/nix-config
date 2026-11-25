# Music grabbing stack: Lidarr searches via Prowlarr and "downloads" through
# Decypharr, which poses as qBittorrent but hands torrents to TorBox (RealDebrid
# can be added in its wizard later). The torrenting happens at the debrid
# provider, so only indexer traffic (Prowlarr) and Soulseek P2P (slskd) need
# the VPN: both run in the airvpn network namespace (VPN-Confinement), whose
# kill switch drops anything that would leave outside the AirVPN tunnel.
# ddg-fetcher (BookOrbit's Anna's Archive solver) runs direct by user choice.
{ config, lib, pkgs, username, ... }:
let
  netns = config.vpnNamespaces.airvpn;
  netnsPorts = lib.concatMapStringsSep "," (m: toString m.from) netns.portMappings;
in
{
  age.secrets.airvpn-wg.file = ../../secrets/airvpn-wg.conf.age;
  # PROWLARR__AUTH__APIKEY
  age.secrets.prowlarr-env.file = ../../secrets/prowlarr-env.age;
  # LIDARR__AUTH__APIKEY — Prowlarr, soularr, digarr and Decypharr all use
  # this key, so the value must never change.
  age.secrets.lidarr-env.file = ../../secrets/lidarr-env.age;

  vpnNamespaces.airvpn = {
    enable = true;
    wireguardConfigFile = config.age.secrets.airvpn-wg.path;
    # LAN and Tailscale clients reach the Prowlarr/slskd UIs through the port
    # mappings; 10.88.0.0/16 is podman's subnet (soularr and digarr call the
    # slskd API through the mapped host port) — the namespace needs a route
    # back to it or replies would vanish into the tunnel.
    allowedIngress = [
      "192.168.1.0/24"
      "100.64.0.0/10"
      "10.88.0.0/16"
    ];
    # The bridge address is the host as seen from the namespace; Prowlarr
    # reaches Lidarr at http://192.168.15.5:8686 through it.
    allowedEgress = [ "192.168.15.5" ];
    # Prowlarr and slskd UIs on the host; LAN/tailnet traffic to these is
    # DNAT'd into the namespace, so they must NOT be in the host firewall.
    portMappings = [
      9696
      5030
    ];
    # AirVPN's fixed port forward (reserved in the Client Area) so Soulseek
    # peers can connect in; slskd listens on it (soulseek.nix).
    vpn.allowedTCPPorts = [ config.services.slskd.settings.soulseek.listen_port ];
    vpn.allowedUDPPorts = [ config.services.slskd.settings.soulseek.listen_port ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/decypharr 0750 ${username} users -"
    # Decypharr writes here, Lidarr imports into /srv/music; same path inside
    # and outside the container so no remote path mapping is needed in Lidarr.
    "d /srv/downloads 0775 ${username} users -"
  ];

  services.prowlarr = {
    enable = true;
    settings = {
      server = {
        port = 9696;
        bindaddress = "*";
        authenticationmethod = "forms";
        authenticationrequired = "enabled";
        # Empty = accept any Host header. The UI is LAN/tailnet-only behind
        # forms auth, and listing addresses here would publish tailnet
        # details in a public repo.
        allowedhosts = "";
      };
      log.level = "debug";
    };
    environmentFiles = [ config.age.secrets.prowlarr-env.path ];
  };
  systemd.services.prowlarr.vpnConfinement = {
    enable = true;
    vpnNamespace = "airvpn";
  };

  virtualisation.oci-containers.containers.decypharr = {
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
    extraOptions = [
      # NixOS maps the hostname to 127.0.0.2 in /etc/hosts and podman copies
      # that into the container; resolve it to the host instead (Lidarr).
      "--add-host=homeserver:host-gateway"
      "--device=/dev/fuse"
      "--cap-add=SYS_ADMIN"
    ];
  };

  services.lidarr = {
    enable = true;
    # Matches /srv ownership and Decypharr's PUID/PGID so imports just work.
    user = username;
    group = "users";
    openFirewall = true;
    settings = {
      server = {
        port = 8686;
        bindaddress = "*";
        authenticationmethod = "forms";
        authenticationrequired = "enabled";
      };
      log.level = "debug";
    };
    environmentFiles = [ config.age.secrets.lidarr-env.path ];
  };

  networking.firewall.allowedTCPPorts = [
    8282 # Decypharr
  ];

  # VPN-Confinement's portMappings only DNAT in PREROUTING, which host-local traffic skips.
  networking.firewall.extraCommands = ''
    iptables -t nat -N netns-local-dnat 2>/dev/null || iptables -t nat -F netns-local-dnat
    iptables -t nat -N netns-local-snat 2>/dev/null || iptables -t nat -F netns-local-snat
    iptables -t nat -A netns-local-dnat -o lo -p tcp -m multiport --dports ${netnsPorts} -j DNAT --to-destination ${netns.namespaceAddress}
    iptables -t nat -A netns-local-snat -p tcp -d ${netns.namespaceAddress} -m multiport --dports ${netnsPorts} -j SNAT --to-source ${netns.bridgeAddress}
    iptables -t nat -C OUTPUT -j netns-local-dnat 2>/dev/null || iptables -t nat -A OUTPUT -j netns-local-dnat
    iptables -t nat -C POSTROUTING -j netns-local-snat 2>/dev/null || iptables -t nat -I POSTROUTING 1 -j netns-local-snat
  '';
  networking.firewall.extraStopCommands = ''
    iptables -t nat -D OUTPUT -j netns-local-dnat 2>/dev/null || true
    iptables -t nat -D POSTROUTING -j netns-local-snat 2>/dev/null || true
    iptables -t nat -F netns-local-dnat 2>/dev/null || true
    iptables -t nat -X netns-local-dnat 2>/dev/null || true
    iptables -t nat -F netns-local-snat 2>/dev/null || true
    iptables -t nat -X netns-local-snat 2>/dev/null || true
  '';
  systemd.services.airvpn.serviceConfig.ExecStartPost =
    "${pkgs.procps}/bin/sysctl -w net.ipv4.conf.airvpn-br.route_localnet=1";
}
