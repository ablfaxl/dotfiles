#!/usr/bin/env bash
# Set Alacritty as the default terminal on Ubuntu/GNOME (and x-terminal-emulator).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$ROOT/lib/common.sh"

if ! command_exists alacritty; then
  err "alacritty not installed — run: make ubuntu-packages"
  exit 1
fi

ALAC="$(command -v alacritty)"

step "Default terminal → Alacritty ($ALAC)"

# 1) Debian/Ubuntu alternatives (Ctrl+Alt+T / x-terminal-emulator)
if command_exists update-alternatives && [[ -x /usr/bin/alacritty ]]; then
  if [[ "$(id -u)" -eq 0 ]] || command_exists sudo; then
    run_root update-alternatives --set x-terminal-emulator /usr/bin/alacritty 2>/dev/null \
      || run_root update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/alacritty 50
    run_root update-alternatives --set x-terminal-emulator /usr/bin/alacritty
    ok "x-terminal-emulator → alacritty"
  else
    warn "Need root to set x-terminal-emulator"
  fi
fi

# 2) GNOME default terminal app
if command_exists gsettings; then
  gsettings set org.gnome.desktop.default-applications.terminal exec 'alacritty'
  gsettings set org.gnome.desktop.default-applications.terminal exec-arg '-e'
  ok "GNOME default terminal → alacritty"
fi

# 3) Ensure desktop entry is known to the session
if [[ -f /usr/share/applications/Alacritty.desktop ]] && command_exists update-desktop-database; then
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

# 4) Persist TERMINAL for scripts / i3 / etc.
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
local_zsh="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/local.zsh"
if [[ -f "$local_zsh" ]] && grep -q 'export TERMINAL=' "$local_zsh" 2>/dev/null; then
  ok "TERMINAL already set in local.zsh"
else
  printf '\n# Default terminal (managed by set-default-terminal.sh)\nexport TERMINAL=alacritty\n' >>"$local_zsh"
  ok "Appended TERMINAL=alacritty to local.zsh"
fi

echo
info "Verify:  x-terminal-emulator -v   OR   Ctrl+Alt+T"
info "Reload:  exec zsh -l"
