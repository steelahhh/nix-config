{ ... }:
let
  worktreePlugin = "https://github.com/sharph/zellij-worktree/releases/latest/download/zellij-worktree.wasm";
in
{
  programs.zellij = {
    enable = true;
    enableZshIntegration = false;
    settings = {
      default_shell = "zsh";
      default_mode = "locked";
      pane_frames = false;
      copy_on_select = true;
      show_startup_tips = false;
      theme = "ayu-mirage";
      session_serialization = true;

      plugins.worktree._props.location = worktreePlugin;

      keybinds.shared_except = {
        _args = [ "locked" "tab" ];
        bind = {
          _args = [ "Ctrl w" ];
          LaunchOrFocusPlugin = {
            _args = [ worktreePlugin ];
            floating = true;
          };
        };
      };
    };
  };

  programs.zsh.sessionVariables = {
    ZELLIJ_AUTO_ATTACH = "false";
  };
}
