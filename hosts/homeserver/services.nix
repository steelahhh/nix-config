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

  # Password is separate from the login: sudo smbpasswd -a sasha
  services.samba = {
    enable = true;
    openFirewall = true;
    settings =
      let
        share = path: {
          inherit path;
          "valid users" = "sasha";
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
