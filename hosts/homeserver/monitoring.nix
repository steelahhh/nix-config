{ config, lib, pkgs, ... }:
let
  # Expects a report at least every `interval`; alerts on a failed or missing report.
  heartbeat = name: interval: {
    inherit name;
    group = "jobs";
    token = "\${GATUS_TOKEN}";
    heartbeat.interval = interval;
    # Threshold 1: a daily job can't wait for 3 failures (that would be 3 days),
    # and one good run after a failure must resolve it (a daily job only ever
    # reports once in a row).
    alerts = [ { type = "ntfy"; failure-threshold = 1; success-threshold = 1; send-on-resolved = true; } ];
  };
  # Attach to a systemd unit: reports success or failure to Gatus when the unit ends.
  report = key: {
    serviceConfig.EnvironmentFile = [ config.age.secrets.gatus-env.path ];
    serviceConfig.ExecStopPost = toString (pkgs.writeShellScript "gatus-report-${key}" ''
      ok=false; [ "$SERVICE_RESULT" = success ] && ok=true
      ${pkgs.curl}/bin/curl -fsS --retry 3 -o /dev/null -X POST \
        -H "Authorization: Bearer $GATUS_TOKEN" \
        "http://localhost:3001/api/v1/endpoints/${key}/external?success=$ok"
    '');
  };
  http = name: url: {
    inherit name url;
    group = "services";
    interval = "5m";
    conditions = [ "[STATUS] == 200" ];
    alerts = [ { type = "ntfy"; } ];
  };
in
{
  age.secrets.gatus-env.file = ../../secrets/gatus-env.age;

  services.gatus = {
    enable = true;
    environmentFile = config.age.secrets.gatus-env.path;
    settings = {
      web.port = 3001; # Uptime Kuma's old port: Homepage link and firewall rule stay valid
      storage = {
        type = "sqlite";
        path = "/var/lib/gatus/data.db";
      };
      alerting.ntfy = {
        url = "http://localhost:2586";
        topic = "homeserver-alerts";
        default-alert = {
          failure-threshold = 3;
          success-threshold = 2;
          send-on-resolved = true;
        };
      };
      endpoints = [
        (http "ntfy" "http://localhost:2586/v1/health")
        (http "Navidrome" "http://homeserver:4533")
        (http "BookOrbit" "http://homeserver:3030")
        (http "Lidarr" "http://homeserver:8686")
        # Prowlarr and slskd live in the airvpn namespace (arr.nix). Host-local
        # traffic skips the namespace's PREROUTING port mapping, so probe the
        # namespace address directly; LAN/tailnet keep using homeserver:9696/5030.
        (http "Prowlarr" "http://192.168.15.1:9696")
        (http "Decypharr" "http://homeserver:8282")
        (http "SABnzbd" "http://homeserver:8080")
        (http "slskd" "http://192.168.15.1:5030")
        (http "Soularr" "http://homeserver:8265")
        (http "digarr" "http://homeserver:5000")
        (http "Gatus" "http://localhost:3001")
      ];
      external-endpoints = [
        (heartbeat "vpn-tunnel" "30m")
      ];
    };
  };

  # Fails if the tunnel is down or traffic exits in Norway — the AirVPN
  # Europe pool changes exit country, so any non-Norwegian country passes.
  systemd.services.vpn-tunnel-check = lib.recursiveUpdate (report "jobs_vpn-tunnel") {
    serviceConfig.Type = "oneshot";
    script = ''
      country="$(${pkgs.iproute2}/bin/ip netns exec airvpn ${pkgs.curl}/bin/curl -fsS --max-time 20 https://ipinfo.io/country)"
      [ -n "$country" ] && [ "$country" != "NO" ]
    '';
  };
  systemd.timers.vpn-tunnel-check = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "10m";
    };
  };
}
