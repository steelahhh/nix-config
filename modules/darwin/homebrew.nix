{ self, ... }:
{
  # Manage homebrew manually
  homebrew.enable = false;

  # Activation runs as root; drop to the login user for brew.
  system.activationScripts.postActivation.text = ''
    # nix-darwin's activation framework redirects this script's stdio.
    # Route our output to the controlling terminal so it shows up live.
    exec > /dev/tty 2>&1

    USER_NAME="ignis"
    BREW=/opt/homebrew/bin/brew
    as_user() { /usr/bin/sudo -u "$USER_NAME" -H "$@"; }
    log() { echo ">>> $*"; }

    if ! [ -x "$BREW" ]; then
      log "Installing Homebrew..."
      as_user /usr/bin/env NONINTERACTIVE=1 /bin/bash -c \
        "$(/usr/bin/curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    log "brew update / upgrade..."
    # Tolerate network/formula hiccups — don't block darwin-rebuild.
    as_user "$BREW" update  || log "brew update failed (continuing)"
    as_user "$BREW" upgrade || log "brew upgrade failed (continuing)"

    log "brew bundle install..."
    # Intentionally NOT tolerant: bundle drift is what we're enforcing.
    as_user "$BREW" bundle install --file=${self}/Brewfile
  '';
}
