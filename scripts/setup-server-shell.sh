#!/usr/bin/env bash
# Setup a graceful server shell on Debian/Ubuntu or Arch Linux.
# Usage:
#   ./scripts/setup-server-shell.sh
#   ./scripts/setup-server-shell.sh --yes
#   curl -fsSL ... | bash   # if hosted later

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER_ROOT="$ROOT/server-config"
ASSUME_YES=0
SKIP_PACKAGES=0
SKIP_SHELL=0
USE_IRAN_MIRROR=0
IRAN_MIRROR_ID=""

# shellcheck source=../lib/common.sh
source "$ROOT/lib/common.sh"

usage() {
  cat <<'EOF'
Graceful server shell — Debian / Ubuntu / Arch

Usage:
  ./scripts/setup-server-shell.sh [options]

Options:
  --yes, -y       Skip confirmation prompts
  --iran          Use Iran mirrors (prompt / default ArvanCloud)
  --mirror <id>   Iran mirror id: arvan | iut | iust | um  (implies --iran)
  --no-packages   Only link configs (skip package install)
  --no-shell      Do not change login shell to zsh
  -h, --help      Show this help

Examples:
  ./scripts/setup-server-shell.sh --yes --iran
  ./scripts/setup-server-shell.sh --yes --mirror iut
  ./server-config/mirrors/setup-iran-mirrors.sh --list
  ./server-config/mirrors/setup-iran-mirrors.sh --mirror um
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --yes|-y) ASSUME_YES=1; shift ;;
      --iran) USE_IRAN_MIRROR=1; shift ;;
      --mirror)
        USE_IRAN_MIRROR=1
        IRAN_MIRROR_ID="$2"
        shift 2
        ;;
      --mirror=*)
        USE_IRAN_MIRROR=1
        IRAN_MIRROR_ID="${1#*=}"
        shift
        ;;
      --no-packages) SKIP_PACKAGES=1; shift ;;
      --no-shell) SKIP_SHELL=1; shift ;;
      -h|--help) usage; exit 0 ;;
      *) err "Unknown option: $1"; usage; exit 1 ;;
    esac
  done
}

detect_distro() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID:-}${ID_LIKE:-}" in
      *arch*) echo "arch" ;;
      *debian*|*ubuntu*) echo "debian" ;;
      *)
        if [[ -f /etc/arch-release ]]; then echo "arch"
        elif [[ -f /etc/debian_version ]]; then echo "debian"
        else echo "unknown"
        fi
        ;;
    esac
  elif [[ -f /etc/arch-release ]]; then
    echo "arch"
  elif [[ -f /etc/debian_version ]]; then
    echo "debian"
  else
    echo "unknown"
  fi
}

read_pkg_list() {
  local file="$1"
  local -n _out="$2"
  _out=()
  [[ -f "$file" ]] || return 0
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line//[[:space:]]/}" ]] && continue
    _out+=("$line")
  done <"$file"
}

install_packages() {
  local distro="$1"
  local pkgs=()

  case "$distro" in
    debian)
      read_pkg_list "$SERVER_ROOT/packages/debian.txt" pkgs
      step "Installing packages via apt (${#pkgs[@]})"

      # Docker.com apt repo often returns 403 from some networks (e.g. IR) and blocks apt update
      if [[ -f "$SERVER_ROOT/mirrors/setup-iran-mirrors.sh" ]]; then
        # shellcheck source=../server-config/mirrors/setup-iran-mirrors.sh
        source "$SERVER_ROOT/mirrors/setup-iran-mirrors.sh"
        disable_broken_apt_repos
      fi

      if ! sudo apt-get update; then
        warn "apt-get update failed — retry after neutralizing broken repos"
        disable_broken_apt_repos 2>/dev/null || true
        sudo apt-get update
      fi

      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}"
      if command_exists fdfind && ! command_exists fd; then
        mkdir -p "$HOME/.local/bin"
        ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
        ok "Linked fdfind -> ~/.local/bin/fd"
      fi
      if command_exists batcat && ! command_exists bat; then
        mkdir -p "$HOME/.local/bin"
        ln -sfn "$(command -v batcat)" "$HOME/.local/bin/bat"
        ok "Linked batcat -> ~/.local/bin/bat"
      fi
      ;;
    arch)
      read_pkg_list "$SERVER_ROOT/packages/arch.txt" pkgs
      step "Installing packages via pacman (${#pkgs[@]})"
      sudo pacman -Syu --needed --noconfirm "${pkgs[@]}"
      ;;
    *)
      err "Unsupported distro. Use Debian/Ubuntu or Arch."
      exit 1
      ;;
  esac
}

install_starship() {
  if command_exists starship; then
    ok "starship already installed"
    return
  fi
  step "Installing starship prompt"
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y
  if [[ -x "$HOME/.local/bin/starship" ]]; then
    ok "starship installed to ~/.local/bin"
  elif command_exists starship; then
    ok "starship installed"
  else
    warn "starship install finished but binary not found on PATH"
  fi
}

# Lazydocker — terminal UI for Docker containers / compose
# Docs: https://lazydocker.com/
# Official Linux install script puts binary in $HOME/.local/bin (override with DIR=)
install_lazydocker() {
  if command_exists lazydocker; then
    ok "lazydocker already installed"
    return
  fi

  step "Installing lazydocker"

  # Arch: prefer pacman when the package exists
  if [[ -f /etc/arch-release ]] && pacman -Si lazydocker &>/dev/null; then
    sudo pacman -S --needed --noconfirm lazydocker
    ok "lazydocker installed via pacman"
    return
  fi

  ensure_dir "$HOME/.local/bin"
  info "Downloading official Linux install script (jesseduffield/lazydocker)"
  # Verify upstream before piping: https://github.com/jesseduffield/lazydocker
  # https://lazydocker.com/
  curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh \
    | DIR="$HOME/.local/bin" bash

  if command_exists lazydocker || [[ -x "$HOME/.local/bin/lazydocker" ]]; then
    ok "lazydocker installed to ~/.local/bin"
  else
    warn "lazydocker install finished but binary not found — install manually from https://lazydocker.com/"
  fi
}

# Netdata — real-time metrics dashboard (https://www.netdata.cloud/)
install_netdata() {
  if command_exists netdata || systemctl is-active --quiet netdata 2>/dev/null; then
    ok "netdata already installed"
    return
  fi

  step "Installing netdata"

  # Arch: prefer official package (also listed in packages/arch.txt)
  if [[ -f /etc/arch-release ]]; then
    if pacman -Qi netdata &>/dev/null; then
      ok "netdata already present via pacman"
    elif pacman -Si netdata &>/dev/null; then
      sudo pacman -S --needed --noconfirm netdata
      sudo systemctl enable --now netdata 2>/dev/null || true
      ok "netdata installed via pacman"
    else
      warn "netdata package not found in pacman — falling back to kickstart"
      curl -fsSL https://get.netdata.cloud/kickstart.sh \
        | sh -s -- --non-interactive --stable-channel --disable-telemetry
    fi
  else
    # Debian/Ubuntu: kickstart for a current, supported install
    info "Installing netdata via official kickstart (non-interactive)"
    curl -fsSL https://get.netdata.cloud/kickstart.sh \
      | sh -s -- --non-interactive --stable-channel --disable-telemetry
  fi

  if command_exists netdata || systemctl list-unit-files netdata.service &>/dev/null; then
    ok "netdata installed — dashboard usually at http://localhost:19999"
  else
    warn "netdata may need a manual check — see https://learn.netdata.cloud/"
  fi
}

link_server_configs() {
  step "Linking server shell configs"
  ensure_dir "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share" "$HOME/.cache"

  link_file "$SERVER_ROOT/env" "$HOME/.config/env"
  link_file "$SERVER_ROOT/aliasrc" "$HOME/.config/aliasrc"
  link_file "$SERVER_ROOT/zsh" "$HOME/.config/zsh"
  link_file "$SERVER_ROOT/tmux" "$HOME/.config/tmux"
  link_file "$SERVER_ROOT/starship.toml" "$HOME/.config/starship.toml"
  link_file "$SERVER_ROOT/home/zshenv" "$HOME/.zshenv"
  link_file "$SERVER_ROOT/home/zprofile" "$HOME/.zprofile"

  # Lightweight bins useful on servers
  local script dest
  for script in killport port localip ex topmem; do
    if [[ -f "$ROOT/bin/$script" ]]; then
      dest="$HOME/.local/bin/$script"
      link_file "$ROOT/bin/$script" "$dest"
      chmod +x "$ROOT/bin/$script"
    fi
  done
}

set_zsh_shell() {
  [[ "$SKIP_SHELL" -eq 1 ]] && return
  if ! command_exists zsh; then
    warn "zsh not found — skip changing login shell"
    return
  fi
  local zsh_path
  zsh_path="$(command -v zsh)"
  if [[ "${SHELL:-}" == "$zsh_path" ]]; then
    ok "Login shell already zsh"
    return
  fi
  if [[ "$ASSUME_YES" -eq 1 ]] || confirm "Set zsh as default login shell?"; then
    if ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
      echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi
    chsh -s "$zsh_path"
    ok "Login shell set to $zsh_path (re-login to apply)"
  fi
}

main() {
  parse_args "$@"

  cat <<EOF

${C_CYAN}${C_BOLD}┌──────────────────────────────────────────────┐
│  Server shell · Debian / Ubuntu / Arch       │
│  Lightweight · graceful · SSH-friendly       │
└──────────────────────────────────────────────┘${C_RESET}

EOF

  if [[ "$(uname -s)" != "Linux" ]]; then
    err "This script targets Linux servers (Debian/Ubuntu/Arch)."
    exit 1
  fi

  local distro
  distro="$(detect_distro)"
  info "Detected distro: $distro"

  if [[ "$ASSUME_YES" -ne 1 ]]; then
    confirm "Install graceful server shell?" || { warn "Aborted"; exit 0; }
  fi

  if [[ "$USE_IRAN_MIRROR" -eq 1 ]]; then
    step "Applying Iran mirrors"
    if [[ -n "$IRAN_MIRROR_ID" ]]; then
      bash "$SERVER_ROOT/mirrors/setup-iran-mirrors.sh" --mirror "$IRAN_MIRROR_ID"
    else
      bash "$SERVER_ROOT/mirrors/setup-iran-mirrors.sh"
    fi
  fi

  if [[ "$SKIP_PACKAGES" -eq 0 ]]; then
    install_packages "$distro"
    install_starship
    install_lazydocker
    install_netdata
  fi

  link_server_configs
  set_zsh_shell

  cat <<EOF

${C_GREEN}${C_BOLD}Server shell ready.${C_RESET}

Next steps:
  1. Reload shell:   ${C_DIM}exec zsh -l${C_RESET}
  2. Open tmux:      ${C_DIM}tmux${C_RESET}  (prefix: Ctrl-a)
  3. Docker TUI:     ${C_DIM}lazydocker${C_RESET}  (alias: ld)
  4. System monitor: ${C_DIM}btop${C_RESET}  (alias: bt)
  5. Metrics UI:     ${C_DIM}http://SERVER_IP:19999${C_RESET}  (netdata)
  6. Customize:      ${C_DIM}~/.config/zsh/local.zsh${C_RESET}

EOF
}

main "$@"
