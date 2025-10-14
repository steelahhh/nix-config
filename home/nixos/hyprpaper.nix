{ ... }:
{
  home.file.".config/hypr/hyprpaper.conf".text =
    let
      wall1 = "${../../wallpapers/wall1.jpg}";
    in
    "
  preload = ${wall1}
  preload = ${wall1}
  wallpaper = eDP-1,${wall1}
  wallpaper = HDMI-A-1,${wall1}
  wallpaper = DP-1,${wall1}
  splash = false
  ";
}
