{ pkgs, ... }:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

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
    pkgs.glow
  ];

  fonts.packages = [
    pkgs.monaspace
    pkgs.nerd-fonts.monaspace
    pkgs.ioskeley-mono.standard
  ];

}
