# BookOrbit (bookorbit.app): no NixOS module, so this mirrors upstream's docker-compose.yml.
{ config, pkgs, ... }:
let
  env = config.age.secrets.bookorbit-env.path; # POSTGRES_PASSWORD, JWT_SECRET, SETUP_BOOTSTRAP_TOKEN, BOOK_REQUEST_ENCRYPTION_KEY
  db = {
    POSTGRES_USER = "bookorbit";
    POSTGRES_DB = "bookorbit";
  };
in
{
  age.secrets.bookorbit-env.file = ../../secrets/bookorbit-env.age;

  systemd.tmpfiles.rules = [
    "d /var/lib/bookorbit/app 0750 sasha users -"
    # Postgres (container uid 999) must traverse this; its pgdata subfolder is 0700.
    "d /var/lib/bookorbit/postgres 0755 root root -"
  ];

  # Shared network so the app reaches the database by container name.
  systemd.services.podman-network-bookorbit = {
    wantedBy = [
      "podman-bookorbit-db.service"
      "podman-bookorbit.service"
    ];
    before = [
      "podman-bookorbit-db.service"
      "podman-bookorbit.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = "${pkgs.podman}/bin/podman network exists bookorbit || ${pkgs.podman}/bin/podman network create bookorbit";
  };

  virtualisation.oci-containers.containers = {
    # shortcut: raw Postgres files get backed up while running; add a pg_dump before the USB backup phase.
    bookorbit-db = {
      image = "docker.io/pgvector/pgvector:pg18";
      environment = db // {
        PGDATA = "/var/lib/postgresql/data/pgdata";
      };
      environmentFiles = [ env ];
      volumes = [ "/var/lib/bookorbit/postgres:/var/lib/postgresql/data" ];
      networks = [ "bookorbit" ];
    };

    bookorbit = {
      # Releases are frequent; bump this tag to update.
      image = "ghcr.io/bookorbit/bookorbit:3.8.0";
      dependsOn = [ "bookorbit-db" ];
      # 3000 is kept free for AdGuard Home.
      ports = [ "3030:3000" ];
      environment = db // {
        NODE_ENV = "production";
        PORT = "3000";
        POSTGRES_HOST = "bookorbit-db";
        POSTGRES_PORT = "5432";
        APP_URL = "http://homeserver:3030";
        TZ = config.time.timeZone;
        # sasha:users, owner of /srv/books
        PUID = "1000";
        PGID = "100";
      };
      environmentFiles = [ env ];
      volumes = [
        "/srv/books:/books"
        "/var/lib/bookorbit/app:/data"
        # Same path inside and out: BookOrbit imports completed grabs from the
        # storage path SABnzbd reports. Mount the parent, not complete/: podman
        # auto-creates a missing top-level bind source but fails on nested paths,
        # and the switch-time tmpfiles re-setup races with container restarts.
        "/srv/downloads/sabnzbd:/srv/downloads/sabnzbd"
      ];
      networks = [ "bookorbit" ];
      extraOptions = [
        # NixOS maps the hostname to 127.0.0.2 in /etc/hosts and podman's DNS
        # mirrors that into the container, so "homeserver" would point at the
        # container's own loopback. Resolve it to the host instead (Prowlarr).
        "--add-host=homeserver:host-gateway"
        # Same hardening as upstream's compose file.
        "--init"
        "--read-only"
        "--tmpfs=/tmp"
        "--cap-drop=ALL"
        "--cap-add=CHOWN,DAC_OVERRIDE,FOWNER,SETGID,SETUID"
        "--security-opt=no-new-privileges"
      ];
    };

    # Fetches Anna's Archive pages for BookOrbit's plugin, waiting out
    # DDoS-Guard's JS check in a persistent Camoufox context. FlareSolverr
    # gets a manual CAPTCHA it cannot pass; Byparr and Trawl get 403s
    # (their flows are detected on every egress tested). Speaks just enough
    # of FlareSolverr's /v1 API that the plugin's solver URL is unchanged.
    # Direct egress by user choice 2026-11-15: the VPN stays on torrent
    # points (Prowlarr) only.
    ddg-fetcher = {
      # Byparr v3.1.1 image as the Camoufox base; pin the tested digest,
      # bump deliberately and re-test the fetcher.
      image = "ghcr.io/thephaseless/byparr@sha256:8170ab7b32d8df29b4b74f02707c503f5bd404c4f99d7e28972bef1595e59c66";
      ports = [ "8191:8191" ];
      entrypoint = "/app/.venv/bin/python";
      cmd = [ "/app/ddg-fetcher.py" ];
      environment = {
        PORT = "8191";
        # Solve the check at startup so the first real search is already warm.
        WARM_URL = "https://annas-archive.gl/search?index=&page=1&display=table&acc=aa_download&acc=external_download&ext=epub&ext=mobi&ext=azw3&q=dune";
        TZ = config.time.timeZone;
      };
      volumes = [ "${./ddg-fetcher.py}:/app/ddg-fetcher.py:ro" ];
      extraOptions = [
        # Camoufox needs shared memory; /tmp in RAM avoids SSD wear.
        "--shm-size=512m"
        "--tmpfs=/tmp:size=512M,mode=1777"
        # The entrypoint override bypasses the image's tini; reap browser
        # children with podman's init instead.
        "--init"
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [
    3030 # BookOrbit
    8191 # ddg-fetcher (Anna's Archive)
  ];
}
