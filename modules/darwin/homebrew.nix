{ self, ... }:
{
  homebrew.enable = false;

  system.activationScripts.postActivation.text = ''
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
    as_user "$BREW" update  || log "brew update failed (continuing)"
    as_user "$BREW" upgrade || log "brew upgrade failed (continuing)"

    log "brew bundle install..."
    as_user "$BREW" bundle install --file=${self}/Brewfile
  '';
}
