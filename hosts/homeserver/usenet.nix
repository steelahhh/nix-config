# Usenet (Newshosting) for BookOrbit. SABnzbd is a real download client here
# because BookOrbit's SABnzbd adapter calls API modes Decypharr's emulation
# does not expose (version, get_config). Lidarr's Usenet grabs go through
# Decypharr's SABnzbd emulation instead, so no second client is needed there.
# Usenet is client-server SSL, not P2P: direct egress, outside gluetun.
{ config, lib, username, ... }:
{
  # homeserver doesn't import modules/common; sabnzbd needs unrar (unfree).
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "unrar" ];

  systemd.tmpfiles.rules = [
    "d /var/lib/sabnzbd 0750 ${username} users -"
    # Same path inside and outside the container: BookOrbit imports completed
    # grabs from the storage path SABnzbd reports, so it mounts this tree at
    # the identical path (see bookorbit.nix). The parent needs its own rule:
    # created implicitly (by tmpfiles or podman) it stays root-owned, which
    # makes tmpfiles refuse the leaf rules as an unsafe path transition.
    "d /srv/downloads/sabnzbd 0775 ${username} users -"
    "d /srv/downloads/sabnzbd/incomplete 0775 ${username} users -"
    "d /srv/downloads/sabnzbd/complete 0775 ${username} users -"
  ];

  # Native service; settings below win over UI edits on every restart
  # (allowConfigWrite keeps the UI working; copy UI changes back here).
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
        # The container NATed every client to a bridge IP, so LAN and
        # Tailscale clients all looked "local" (no login). Native sees real
        # source IPs: without the tailnet range here, inet_exposure=none
        # blocks tailnet clients entirely. Setting local_ranges REPLACES
        # SABnzbd's built-ins, so keep them and add 100.64.0.0/10.
        local_ranges = "127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 100.64.0.0/10, ::1/128, fe80::/10";
        cache_limit = "1G";
        direct_unpack = true;
        download_dir = "/srv/downloads/sabnzbd/incomplete";
        download_free = "500M";
        complete_dir = "/srv/downloads/sabnzbd/complete";
      };
      servers."news.newshosting.com" = {
        name = "news.newshosting.com";
        displayname = "news.newshosting.com";
        host = "news.newshosting.com";
        connections = 16;
        pipelining_requests = 2;
      };
      # Categories BookOrbit (bookorbit) and Lidarr/Decypharr (music, lidarr)
      # send jobs with; the rest are SABnzbd's defaults, declared so the
      # generated config matches what the container ran.
      categories =
        let
          # What SABnzbd's default categories (movies/tv/audio/software)
          # and the container-era custom ones look like; pp/dir/newzbin
          # empty means "inherit defaults".
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
    8080 # SABnzbd
  ];
}
