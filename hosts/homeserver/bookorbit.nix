{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  env = config.age.secrets.bookorbit-env.path;
in
{
  age.secrets.bookorbit-env.file = ../../secrets/bookorbit-env.age;

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

  users.users.bookorbit.extraGroups = [ "users" ];
  systemd.services.bookorbit.serviceConfig = {
    # Module default 0077 would make new book files unreadable by sasha and Samba.
    UMask = lib.mkForce "0002";
  };

  virtualisation.oci-containers.containers = {
    ddg-fetcher = {
      image = "ghcr.io/thephaseless/byparr@sha256:8170ab7b32d8df29b4b74f02707c503f5bd404c4f99d7e28972bef1595e59c66";
      ports = [ "8191:8191" ];
      entrypoint = "/app/.venv/bin/python";
      cmd = [ "/app/ddg-fetcher.py" ];
      environment = {
        PORT = "8191";
        WARM_URL = "https://annas-archive.gl/search?index=&page=1&display=table&acc=aa_download&acc=external_download&ext=epub&ext=mobi&ext=azw3&q=dune";
        TZ = config.time.timeZone;
      };
      volumes = [ "${./ddg-fetcher.py}:/app/ddg-fetcher.py:ro" ];
      extraOptions = [
        "--shm-size=512m"
        "--tmpfs=/tmp:size=512M,mode=1777"
        # The entrypoint override bypasses the image's tini; reap browser
        # children with podman's init instead.
        "--init"
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [
    3030
    8191
  ];
}
