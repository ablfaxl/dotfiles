#!/usr/bin/env bash
# Shared helpers for install.sh and bin scripts.

set -euo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Colors (disabled when not a TTY)
if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'
  C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_BLUE=$'\033[34m'
  C_CYAN=$'\033[36m'
else
  C_RESET= C_BOLD= C_DIM= C_RED= C_GREEN= C_YELLOW= C_BLUE= C_CYAN=
fi

info()  { printf '%s==>%s %s\n' "${C_BLUE}${C_BOLD}" "${C_RESET}" "$*"; }
ok()    { printf '%s[ok]%s %s\n' "${C_GREEN}${C_BOLD}" "${C_RESET}" "$*"; }
warn()  { printf '%s[!]%s %s\n' "${C_YELLOW}${C_BOLD}" "${C_RESET}" "$*"; }
err()   { printf '%s[err]%s %s\n' "${C_RED}${C_BOLD}" "${C_RESET}" "$*" >&2; }
step()  { printf '\n%s::%s %s%s%s\n' "${C_CYAN}${C_BOLD}" "${C_RESET}" "${C_BOLD}" "$*" "${C_RESET}"; }

detect_os() {
  case "$(uname -s)" in
    Darwin) echo "mac" ;;
    Linux)  echo "linux" ;;
    *)      echo "unknown" ;;
  esac
}

confirm() {
  local prompt="${1:-Continue?}"
  local default="${2:-y}"
  local reply
  if [[ "$default" == "y" ]]; then
    printf '%s [Y/n] ' "$prompt"
  else
    printf '%s [y/N] ' "$prompt"
  fi
  read -r reply || true
  reply="${reply:-$default}"
  [[ "$reply" =~ ^[Yy]$ ]]
}

backup_path() {
  local target="$1"
  local stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  if [[ -e "$target" || -L "$target" ]]; then
    mv "$target" "${target}.bak.${stamp}"
    warn "Backed up existing file -> ${target}.bak.${stamp}"
  fi
}

# Symlink src → dest. Backs up existing files unless they already point here.
link_file() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname "$dest")"

  if [[ -L "$dest" ]]; then
    local current
    current="$(readlink "$dest")"
    if [[ "$current" == "$src" ]]; then
      ok "Already linked: $dest"
      return 0
    fi
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    backup_path "$dest"
  fi

  ln -sfn "$src" "$dest"
  ok "Linked $dest -> $src"
}

ensure_dir() {
  mkdir -p "$@"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Prefer sudo when available and not already root (containers / recovery shells).
run_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command_exists sudo; then
    sudo "$@"
  else
    err "Need root to run: $*"
    return 1
  fi
}
