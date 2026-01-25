{ pkgs, ... }:
{
  nix.settings.experimental-features = "nix-command flakes";
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = [
    pkgs.neovim
    pkgs.hyfetch
    pkgs.nixd
    pkgs.nixfmt
    pkgs.home-manager
    pkgs.git-machete
    pkgs.zulu21
    pkgs.tokei
    pkgs.gh
    pkgs.ruby
    pkgs.nh
  ];

  fonts.packages = [
    pkgs.monaspace
    pkgs.nerd-fonts.monaspace
  ];

}
