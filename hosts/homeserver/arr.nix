{ config, lib, pkgs, username, ... }:
let
  netns = config.vpnNamespaces.airvpn;
  netnsPorts = lib.concatMapStringsSep "," (m: toString m.from) netns.portMappings;
in
{
  age.secrets.airvpn-wg.file = ../../secrets/airvpn-wg.conf.age;
  age.secrets.prowlarr-env.file = ../../secrets/prowlarr-env.age;
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
    allowedEgress = [ config.vpnNamespaces.airvpn.bridgeAddress ];
    portMappings = [
      9696
      5030
    ];
    vpn.allowedTCPPorts = [ config.services.slskd.settings.soulseek.listen_port ];
    vpn.allowedUDPPorts = [ config.services.slskd.settings.soulseek.listen_port ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/decypharr 0750 ${username} users -"
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
    8282
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
