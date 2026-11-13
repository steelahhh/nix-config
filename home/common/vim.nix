{ pkgs, lib, ... }:
{
  home.file.".ideavimrc".source = ./idea.vimrc;

  # LazyVim: lazy.nvim fetches plugins at runtime; lazy-lock.json stays writable in ~/.config/nvim
  xdg.configFile."nvim/lua".source = ./nvim/lua;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = false;
    initLua = ''require("config.lazy")'';
    # LSPs, linters, formatters and debuggers come from nix instead of Mason
    extraPackages = [
      pkgs.beamPackages.expert
      pkgs.rubyPackages.solargraph
      pkgs.rubocop
      pkgs.gopls
      pkgs.gotools
      pkgs.gofumpt
      pkgs.gomodifytags
      pkgs.impl
      pkgs.golangci-lint
      pkgs.delve
      pkgs.rust-analyzer
      pkgs.lldb
      pkgs.nixd
      pkgs.vscode-langservers-extracted
      pkgs.yaml-language-server
      pkgs.taplo
      pkgs.marksman
      pkgs.markdownlint-cli2
      pkgs.markdown-toc
      pkgs.prettier
      pkgs.dockerfile-language-server
      pkgs.docker-compose-language-service
      pkgs.hadolint
      pkgs.fd
      pkgs.tree-sitter
    ]
    ++ lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.gcc;
  };
}
