# BookOrbit (bookorbit.app): native nixpkgs module + native Postgres.
{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  env = config.age.secrets.bookorbit-env.path; # POSTGRES_PASSWORD (unused, socket auth), JWT_SECRET, SETUP_BOOTSTRAP_TOKEN, BOOK_REQUEST_ENCRYPTION_KEY
in
{
  age.secrets.bookorbit-env.file = ../../secrets/bookorbit-env.age;

  systemd.tmpfiles.rules = [
    # Unused legacy Postgres data dir (container-era pg18); kept as a
    # rollback copy, safe to delete. Its pgdata subfolder is 0700 root.
    "d /var/lib/bookorbit/postgres 0755 root root -"
  ];

  # Native Postgres over the Unix socket (peer auth); the POSTGRES_PASSWORD
  # in the env file is unused. Library paths in the database are host paths
  # (/srv/books), no bind mounts.
  services.postgresql.package = pkgs.postgresql_18;
  services.bookorbit = {
    enable = true;
    createDatabaseLocally = true;
    environmentFile = env;
    environment = {
      PORT = 3030;
      APP_URL = "http://homeserver:3030";
      NODE_ENV = "production";
      TZ = config.time.timeZone;
    };
  };

  # BookOrbit edits and deletes library files in place, so it needs group
  # write on /srv/books: dirs g+rwsX (setgid keeps new subdirs in group users),
  # files g+rw. Without setgid on dirs, subfolders BookOrbit creates stay
  # 0755 and the next edit/delete in them fails EACCES.
  users.users.bookorbit.extraGroups = [ "users" ];
  systemd.services.bookorbit.serviceConfig = {
    # Module default 0077 would make new book files unreadable by sasha and Samba.
    UMask = lib.mkForce "0002";
    # ProtectSystem=full leaves /srv read-only; the library and SABnzbd
    # imports live there. Same paths inside and out, so no path mapping.
    ReadWritePaths = [
      "/srv/books"
      "/srv/downloads/sabnzbd"
    ];
  };

  # ddg-fetcher stays a container (Camoufox base image).
  virtualisation.oci-containers.containers = {

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
