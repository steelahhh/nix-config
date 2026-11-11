{ ... }:
{
  services.navidrome = {
    enable = true;
    openFirewall = true;
    settings = {
      # Default is localhost only; this opens it to the LAN and Tailscale.
      Address = "0.0.0.0";
      Port = 4533;
      MusicFolder = "/srv/music";
    };
  };
}
