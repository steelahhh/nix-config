# Usenet (Newshosting) for BookOrbit. SABnzbd is a real download client here
# because BookOrbit's SABnzbd adapter calls API modes Decypharr's emulation
# does not expose (version, get_config). Lidarr's Usenet grabs go through
# Decypharr's SABnzbd emulation instead, so no second client is needed there.
# Usenet is client-server SSL, not P2P: direct egress, outside gluetun.
{ config, ... }:
{
  systemd.tmpfiles.rules = [
    "d /var/lib/sabnzbd 0750 sasha users -"
    # Same path inside and outside the container: BookOrbit imports completed
    # grabs from the storage path SABnzbd reports, so it mounts this tree at
    # the identical path (see bookorbit.nix). The parent needs its own rule:
    # created implicitly (by tmpfiles or podman) it stays root-owned, which
    # makes tmpfiles refuse the leaf rules as an unsafe path transition.
    "d /srv/downloads/sabnzbd 0775 sasha users -"
    "d /srv/downloads/sabnzbd/incomplete 0775 sasha users -"
    "d /srv/downloads/sabnzbd/complete 0775 sasha users -"
  ];

  virtualisation.oci-containers.containers.sabnzbd = {
    image = "docker.io/linuxserver/sabnzbd:5.1.3";
    ports = [ "8080:8080" ];
    environment = {
      PUID = "1000";
      PGID = "100";
      TZ = config.time.timeZone;
    };
    volumes = [
      "/var/lib/sabnzbd:/config"
      "/srv/downloads/sabnzbd:/srv/downloads/sabnzbd"
    ];
  };

  networking.firewall.allowedTCPPorts = [
    8080 # SABnzbd
  ];
}
