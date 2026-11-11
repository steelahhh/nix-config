# BookOrbit (bookorbit.app): no NixOS module, so this mirrors upstream's docker-compose.yml.
{ config, pkgs, ... }:
let
  env = config.age.secrets.bookorbit-env.path; # POSTGRES_PASSWORD, JWT_SECRET, SETUP_BOOTSTRAP_TOKEN
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
      ];
      networks = [ "bookorbit" ];
      # Same hardening as upstream's compose file.
      extraOptions = [
        "--init"
        "--read-only"
        "--tmpfs=/tmp"
        "--cap-drop=ALL"
        "--cap-add=CHOWN,DAC_OVERRIDE,FOWNER,SETGID,SETUID"
        "--security-opt=no-new-privileges"
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 3030 ];
}
