{ config, lib, username, ... }:
{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "unrar" ];

  systemd.tmpfiles.rules = [
    "d /var/lib/sabnzbd 0750 ${username} users -"
    # The parent needs its own rule: created implicitly it stays root-owned,
    # which makes tmpfiles refuse the leaf rules as an unsafe path transition.
    "d /srv/downloads/sabnzbd 0775 ${username} users -"
    "d /srv/downloads/sabnzbd/incomplete 0775 ${username} users -"
    "d /srv/downloads/sabnzbd/complete 0775 ${username} users -"
  ];

  age.secrets.sabnzbd-secrets = {
    file = ../../secrets/sabnzbd-secrets.ini.age;
    owner = username;
  };
  services.sabnzbd = {
    enable = true;
    user = username;
    group = "users";
    allowConfigWrite = true;
    secretFiles = [ config.age.secrets.sabnzbd-secrets.path ];
    settings = {
      misc = {
        host = "0.0.0.0";
        port = 8080;
        # inet_exposure=none blocks non-local source IPs entirely, API
        # keys included, so Tailscale clients must count as local. Setting
        # local_ranges REPLACES SABnzbd's built-ins: keep them and add
        # 100.64.0.0/10.
        local_ranges = "127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 100.64.0.0/10, ::1/128, fe80::/10";
        cache_limit = "1G";
        direct_unpack = true;
        download_dir = "/srv/downloads/sabnzbd/incomplete";
        download_free = "500M";
        complete_dir = "/srv/downloads/sabnzbd/complete";
        permissions = "775";
      };
      servers."news.newshosting.com" = {
        name = "news.newshosting.com";
        displayname = "news.newshosting.com";
        host = "news.newshosting.com";
        connections = 16;
        pipelining_requests = 2;
      };
      categories =
        let
          cat = order: {
            inherit order;
            pp = "";
            script = "Default";
            dir = "";
            newzbin = "";
            priority = -100;
          };
        in
        {
          "*" = {
            order = 0;
            pp = 3;
            script = "Default";
            dir = "";
            newzbin = "";
            priority = 0;
          };
          movies = cat 1;
          tv = cat 2;
          audio = cat 3;
          software = cat 4;
          bookorbit = cat 5;
          music = cat 6;
          lidarr = cat 7;
        };
    };
  };

  networking.firewall.allowedTCPPorts = [
    8080
  ];
}
