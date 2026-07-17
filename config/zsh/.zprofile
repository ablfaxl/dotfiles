#!/bin/zsh
# Login shell — env already loaded via ~/.zprofile; keep for ZDOTDIR users.
. "${XDG_CONFIG_HOME:-$HOME/.config}/env"

# Launch gpg-agent quietly when available
command -v gpgconf >/dev/null 2>&1 && gpgconf --launch gpg-agent 2>/dev/null || true
