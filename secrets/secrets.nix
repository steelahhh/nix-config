let
  # Public keys allowed to decrypt secrets. This file is NOT secret.
  # Dedicated passphrase-less age key (~/.config/age/keys.txt) — required
  # because the launchd decrypt agent runs without a terminal and the SSH
  # keys are passphrase-protected. Public key via: age-keygen -y ~/.config/age/keys.txt
  ignis = "age1v0sdyxxal6a9nk927t952u4zh4u8wwckfkvjxw5sg40rz4ej7cmsnlnp52";
in
{
  "jira_token.age".publicKeys = [ ignis ];
  "jira_email.age".publicKeys = [ ignis ];
}
