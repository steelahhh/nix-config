{ pkgs, config, ... }:
{
  home.packages = [
    pkgs.zsh
  ];

  # agenix: decrypt jira_token.age at activation using the SSH key, then
  # export it into the shell by path (plaintext never enters the nix store).
  age.identityPaths = [ "${config.home.homeDirectory}/.config/age/keys.txt" ];
  age.secrets.jira_token.file = ../../secrets/jira_token.age;
  age.secrets.jira_email.file = ../../secrets/jira_email.age;

  programs.zsh.initContent = ''
    export JIRA_API_TOKEN="$(cat ${config.age.secrets.jira_token.path})"
    export JIRA_EMAIL="$(cat ${config.age.secrets.jira_email.path})"
  '';

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = pkgs.lib.importTOML ./starship/starship.toml;
  };

  programs.zsh = {
    enable = true;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "amuse";
      plugins = [
        "git"
        "fzf"
      ];
    };
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = false;
    enableZshIntegration = true;
    defaultOptions = [
      "--no-mouse"
    ];
  };
}
