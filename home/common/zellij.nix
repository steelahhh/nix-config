{ ... }:
{
  programs.zellij = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      default_shell = "zsh";
      pane_frames = false;
      copy_on_select = true;
      show_startup_tips = false;
      theme = "gruvbox-dark";
      session_serialization = true;
    };
  };

  programs.zsh.sessionVariables = {
    ZELLIJ_AUTO_ATTACH = "true";
  };
}
