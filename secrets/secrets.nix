let
  # Public keys allowed to decrypt secrets. This file is NOT secret.
  # Dedicated passphrase-less age key (~/.config/age/keys.txt) — required
  # because the launchd decrypt agent runs without a terminal and the SSH
  # keys are passphrase-protected. Public key via: age-keygen -y ~/.config/age/keys.txt
  ignis = "age1209n7gem4w6c95yna49rq84we9ryv32lfru52xq4anrq2phj9fdqw0mvtz";
  # homeserver's SSH host key: ssh-keyscan -t ed25519 homeserver
  homeserver = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFERt4iNMqgI4rFyy//BCLLl/5DwjjyVaouyfm5lErfM";
in
{
  "jira_token.age".publicKeys = [ ignis ];
  "jira_email.age".publicKeys = [ ignis ];
  "bookorbit-env.age".publicKeys = [
    ignis
    homeserver
  ];
}
