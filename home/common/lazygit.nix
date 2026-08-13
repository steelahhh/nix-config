{ pkgs, ... }:
{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      side-by-side = false;
    };
  };

  programs.lazygit = {
    enable = true;
    settings = {
      git.diffRenderers = [
        {
          colorArg = "always";
          command = "${pkgs.delta}/bin/delta --dark --paging=never";
        }
      ];
    };
  };
}
