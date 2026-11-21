{ username, ... }:
{
  # Apple Music playlist imports (.m3u8) land here, written as sasha over
  # SSH. Inside MusicFolder, so Navidrome's sandbox binds it read-only —
  # imports work; playlists edited in the UI stay in its database only.
  systemd.tmpfiles.rules = [
    "d /srv/music/playlists 0775 ${username} users -"
  ];

  services.navidrome = {
    enable = true;
    openFirewall = true;
    # ListenBrainz scrobbling is built in: per-user token in the UI, no env.
    withPlugins = p: [ p.listenbrainz-daily-playlist ];
    settings = {
      # Default is localhost only; this opens it to the LAN and Tailscale.
      Address = "0.0.0.0";
      Port = 4533;
      MusicFolder = "/srv/music";
      PlaylistsPath = "/srv/music/playlists";
    };
  };

  # Monitors and alerts are set up in its web UI.
  services.uptime-kuma = {
    enable = true;
    settings.HOST = "0.0.0.0";
  };
  # 80: Caddy (Homepage), 3001: Uptime Kuma
  networking.firewall.allowedTCPPorts = [
    80
    3001
  ];

  services.homepage-dashboard = {
    enable = true;
    openFirewall = true;
    # Homepage rejects requests for hostnames not listed here.
    allowedHosts = "homeserver,homeserver:8082,localhost:8082";
    services = [
      {
        "Media" = [
          {
            "Navidrome" = {
              href = "http://homeserver:4533";
              description = "Music";
            };
          }
          {
            "BookOrbit" = {
              href = "http://homeserver:3030";
              description = "Books";
            };
          }
          {
            "Lidarr" = {
              href = "http://homeserver:8686";
              description = "Music automation";
            };
          }
          {
            "Prowlarr" = {
              href = "http://homeserver:9696";
              description = "Torrent/Usenet indexers (VPN)";
            };
          }
          {
            "Decypharr" = {
              href = "http://homeserver:8282";
              description = "Debrid / Usenet gateway";
            };
          }
          {
            "SABnzbd" = {
              href = "http://homeserver:8080";
              description = "Usenet downloads";
            };
          }
          {
            "slskd" = {
              href = "http://homeserver:5030";
              description = "Soulseek (VPN, download-only)";
            };
          }
          {
            "Soularr" = {
              href = "http://homeserver:8265";
              description = "Soulseek automation";
            };
          }
          {
            "digarr" = {
              href = "http://homeserver:5000";
              description = "Music discovery";
            };
          }
        ];
      }
      {
        "Admin" = [
          {
            "Uptime Kuma" = {
              href = "http://homeserver:3001";
              description = "Service monitoring";
            };
          }
          {
            "Proxmox" = {
              href = "https://pve:8006";
              description = "VM host";
            };
          }
        ];
      }
    ];
  };

  # Serves Homepage at plain http://homeserver; Homepage's hardening blocks it from binding port 80 itself.
  services.caddy = {
    enable = true;
    virtualHosts."http://homeserver".extraConfig = "reverse_proxy localhost:8082";
  };

  # Password is separate from the login: sudo smbpasswd -a sasha
  services.samba = {
    enable = true;
    openFirewall = true;
    settings =
      let
        share = path: {
          inherit path;
          "valid users" = username;
          "read only" = "no";
          "create mask" = "0664";
          "directory mask" = "0775";
        };
      in
      {
        music = share "/srv/music";
        books = share "/srv/books";
      };
  };
}
