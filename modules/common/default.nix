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
    pkgs.nodejs
    pkgs.eza
    pkgs.bat
    pkgs.zoxide
    pkgs.ripgrep
    pkgs.yazi
    pkgs.delta
  ];

  fonts.packages = [
    pkgs.monaspace
    pkgs.nerd-fonts.monaspace
<<<<<<< HEAD
    pkgs.ioskeley-mono.standard
=======
    pkgs.ioskeley-mono
>>>>>>> 3815c17 (feat(nix): cosmic wip)
  ];

}
