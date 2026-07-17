#!/usr/bin/env bash
# Configure Ubuntu/Debian/Arch package mirrors.
# Named Iran presets + full Ubuntu mirror catalog + custom --url.
#
# Examples:
#   ./setup-iran-mirrors.sh
#   ./setup-iran-mirrors.sh --list
#   ./setup-iran-mirrors.sh --list-all
#   ./setup-iran-mirrors.sh --mirror iut
#   ./setup-iran-mirrors.sh --mirror iranserver
#   ./setup-iran-mirrors.sh --url https://mirror.iranserver.com/ubuntu/
#   ./setup-iran-mirrors.sh --auto

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIRRORS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/common.sh
source "$ROOT/lib/common.sh"

MIRROR_ID="${IRAN_MIRROR:-arvan}"
CUSTOM_URL=""
DO_AUTO=0
UBUNTU_MIRRORS_FILE="$MIRRORS_DIR/ubuntu-mirrors.txt"

# id|label|ubuntu_base|debian_base|debian_security|arch_base
# (debian/arch empty = Ubuntu-only preset)
MIRROR_CATALOG=(
  "arvan|ArvanCloud (default)|http://mirror.arvancloud.ir/ubuntu|http://mirror.arvancloud.ir/debian|http://mirror.arvancloud.ir/debian-security|https://mirror.arvancloud.ir/archlinux"
  "iut|Isfahan University of Technology (IUT)|http://mirror.iut.ac.ir/repo/ubuntu|http://mirror.iut.ac.ir/repo/debian|http://mirror.iut.ac.ir/repo/debian-security|https://mirror.iut.ac.ir/repo/archlinux"
  "iut-repo|IUT repo.iut.ac.ir|http://repo.iut.ac.ir/repo/Ubuntu||||"
  "iust|Iran University of Science and Technology (IUST)|http://mirror.iust.ac.ir/ubuntu|http://mirror.iust.ac.ir/debian|http://mirror.iust.ac.ir/debian-security|https://mirror.iust.ac.ir/archlinux"
  "um|Ferdowsi University of Mashhad (UM)|http://mumirror.um.ac.ir/linux/ubuntu|http://mumirror.um.ac.ir/linux/debian|http://mumirror.um.ac.ir/linux/debian-security|https://mumirror.um.ac.ir/linux/archlinux"
  "iranserver|IranServer|https://mirror.iranserver.com/ubuntu||||"
  "sindad|Sindad Cloud (IR)|https://ir.ubuntu.sindad.cloud/ubuntu||||"
  "faraso|Faraso|http://mirror.faraso.org/ubuntu||||"
  "pishgaman|Pishgaman|https://ubuntu.pishgaman.net/ubuntu||||"
  "ir-archive|Ubuntu IR archive|https://ir.archive.ubuntu.com/ubuntu||||"
  "official|Ubuntu official archive|http://archive.ubuntu.com/ubuntu||||"
)

usage() {
  cat <<'EOF'
Package mirrors (Iran presets + global Ubuntu catalog)

Usage:
  ./setup-iran-mirrors.sh [options]

Options:
  --mirror <id>   Named preset (see --list)
  --url <url>     Any Ubuntu archive URL (from --list-all or custom)
  --auto          Probe catalog until apt update succeeds (Ubuntu)
  --list          Show named presets
  --list-all      Show full ubuntu-mirrors.txt catalog
  -h, --help      Show this help

Env:
  IRAN_MIRROR=<id>   same as --mirror
EOF
}

normalize_ubuntu_url() {
  local u="$1"
  u="${u%/}"
  printf '%s\n' "$u"
}

list_presets() {
  printf '\n%-12s  %s\n' "ID" "PROVIDER"
  printf '%-12s  %s\n' "------------" "----------------------------------------------"
  local row id label
  for row in "${MIRROR_CATALOG[@]}"; do
    IFS='|' read -r id label _ <<<"$row"
    printf '%-12s  %s\n' "$id" "$label"
  done
  echo
  info "Full Ubuntu catalog: --list-all  ($(grep -cE '^https?://' "$UBUNTU_MIRRORS_FILE" 2>/dev/null || echo 0) mirrors)"
}

list_all_ubuntu() {
  if [[ ! -f "$UBUNTU_MIRRORS_FILE" ]]; then
    err "Missing $UBUNTU_MIRRORS_FILE"
    exit 1
  fi
  echo
  grep -E '^https?://' "$UBUNTU_MIRRORS_FILE" || true
  echo
  info "$(grep -cE '^https?://' "$UBUNTU_MIRRORS_FILE") mirrors in ubuntu-mirrors.txt"
}

resolve_preset() {
  local want="$1"
  local row id label ubuntu debian security arch
  for row in "${MIRROR_CATALOG[@]}"; do
    IFS='|' read -r id label ubuntu debian security arch <<<"$row"
    if [[ "$id" == "$want" ]]; then
      IRAN_MIRROR_LABEL="$label"
      IRAN_UBUNTU_MIRROR="$(normalize_ubuntu_url "$ubuntu")"
      IRAN_DEBIAN_MIRROR="${debian:-}"
      IRAN_DEBIAN_SECURITY="${security:-}"
      IRAN_ARCH_MIRROR="${arch:-}"
      return 0
    fi
  done
  err "Unknown mirror id: $want (use --list)"
  return 1
}

parse_mirror_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mirror)
        MIRROR_ID="$2"
        CUSTOM_URL=""
        shift 2
        ;;
      --mirror=*)
        MIRROR_ID="${1#*=}"
        CUSTOM_URL=""
        shift
        ;;
      --url)
        CUSTOM_URL="$(normalize_ubuntu_url "$2")"
        shift 2
        ;;
      --url=*)
        CUSTOM_URL="$(normalize_ubuntu_url "${1#*=}")"
        shift
        ;;
      --auto)
        DO_AUTO=1
        shift
        ;;
      --list|-l)
        list_presets
        exit 0
        ;;
      --list-all)
        list_all_ubuntu
        exit 0
        ;;
      -h|--help)
        usage
        list_presets
        exit 0
        ;;
      *)
        if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
          err "Unknown option: $1"
          usage
          exit 1
        fi
        shift
        ;;
    esac
  done
}

ask_mirror_interactive() {
  [[ -t 0 ]] || return 0
  list_presets
  printf 'Select preset id [%s] (or paste a full mirror URL): ' "$MIRROR_ID"
  local choice=""
  read -r choice || true
  [[ -z "${choice:-}" ]] && return 0
  if [[ "$choice" =~ ^https?:// ]]; then
    CUSTOM_URL="$(normalize_ubuntu_url "$choice")"
  else
    MIRROR_ID="$choice"
  fi
}

disable_broken_apt_repos() {
  step "Disabling broken third-party apt repos (e.g. Docker 403)"
  local f
  shopt -s nullglob
  for f in /etc/apt/sources.list.d/*docker* \
           /etc/apt/sources.list.d/*Docker* \
           /etc/apt/sources.list.d/download_docker_com* ; do
    if [[ -f "$f" && "$f" != *.disabled ]]; then
      sudo mv "$f" "${f}.disabled"
      ok "Disabled $f"
    fi
  done
  shopt -u nullglob
}

backup_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    local stamp
    stamp="$(date +%Y%m%d-%H%M%S)"
    sudo cp -a "$path" "${path}.bak.${stamp}"
    ok "Backed up $path"
  fi
}

write_ubuntu_sources() {
  # shellcheck disable=SC1091
  . /etc/os-release
  local codename="${VERSION_CODENAME:-jammy}"
  local mirror
  mirror="$(normalize_ubuntu_url "$1")"
  local label="${2:-custom}"

  step "Configuring Ubuntu mirror ($codename)"
  info "Provider: $label"
  info "URL: $mirror"
  backup_file /etc/apt/sources.list

  if [[ -f /etc/apt/sources.list.d/ubuntu.sources ]]; then
    backup_file /etc/apt/sources.list.d/ubuntu.sources
    sudo tee /etc/apt/sources.list.d/ubuntu.sources >/dev/null <<EOF
Types: deb
URIs: ${mirror}
Suites: ${codename} ${codename}-updates ${codename}-backports ${codename}-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
    echo "# Managed by server-config mirrors — see ubuntu.sources" | sudo tee /etc/apt/sources.list >/dev/null
  else
    sudo tee /etc/apt/sources.list >/dev/null <<EOF
# Ubuntu mirror — ${label}
# Generated by server-config
deb ${mirror} ${codename} main restricted universe multiverse
deb ${mirror} ${codename}-updates main restricted universe multiverse
deb ${mirror} ${codename}-backports main restricted universe multiverse
deb ${mirror} ${codename}-security main restricted universe multiverse
EOF
  fi

  disable_broken_apt_repos
}

configure_ubuntu_iran() {
  write_ubuntu_sources "$IRAN_UBUNTU_MIRROR" "$IRAN_MIRROR_LABEL"
  sudo apt-get update
  ok "Ubuntu mirror active"
}

configure_debian_iran() {
  # shellcheck disable=SC1091
  . /etc/os-release
  local codename="${VERSION_CODENAME:-bookworm}"

  if [[ -z "${IRAN_DEBIAN_MIRROR:-}" ]]; then
    err "Selected preset has no Debian mirror — pick arvan/iut/iust/um or use Ubuntu"
    exit 1
  fi

  step "Configuring Debian Iran mirror ($codename)"
  info "Provider: $IRAN_MIRROR_LABEL"
  backup_file /etc/apt/sources.list
  sudo tee /etc/apt/sources.list >/dev/null <<EOF
# Debian mirror — ${IRAN_MIRROR_LABEL}
# Generated by server-config
deb ${IRAN_DEBIAN_MIRROR} ${codename} main contrib non-free non-free-firmware
deb ${IRAN_DEBIAN_MIRROR} ${codename}-updates main contrib non-free non-free-firmware
deb ${IRAN_DEBIAN_SECURITY} ${codename}-security main contrib non-free non-free-firmware
EOF
  disable_broken_apt_repos
  sudo apt-get update
  ok "Debian mirror active ($MIRROR_ID)"
}

configure_arch_iran() {
  if [[ -z "${IRAN_ARCH_MIRROR:-}" ]]; then
    err "Selected preset has no Arch mirror — pick arvan/iut/iust/um"
    exit 1
  fi
  step "Configuring Arch Iran mirror"
  info "Provider: $IRAN_MIRROR_LABEL"
  info "URL: $IRAN_ARCH_MIRROR"
  backup_file /etc/pacman.d/mirrorlist
  sudo tee /etc/pacman.d/mirrorlist >/dev/null <<EOF
# Arch mirror — ${IRAN_MIRROR_LABEL}
# Generated by server-config
Server = ${IRAN_ARCH_MIRROR}/\$repo/os/\$arch
EOF
  sudo pacman -Sy
  ok "Arch mirror active ($MIRROR_ID)"
}

probe_ubuntu_mirrors() {
  step "Auto-probing Ubuntu mirrors until apt update works"
  disable_broken_apt_repos

  local candidates=()
  local row id label ubuntu
  for row in "${MIRROR_CATALOG[@]}"; do
    IFS='|' read -r id label ubuntu _ <<<"$row"
    [[ -n "$ubuntu" ]] && candidates+=("$ubuntu|$label")
  done
  if [[ -f "$UBUNTU_MIRRORS_FILE" ]]; then
    local u
    while IFS= read -r u; do
      [[ "$u" =~ ^https?:// ]] || continue
      candidates+=("$(normalize_ubuntu_url "$u")|catalog")
    done <"$UBUNTU_MIRRORS_FILE"
  fi

  local entry mirror label
  local tried=0
  for entry in "${candidates[@]}"; do
    mirror="${entry%%|*}"
    label="${entry#*|}"
    tried=$((tried + 1))
    info "[$tried] Trying $mirror"
    write_ubuntu_sources "$mirror" "$label"
    if sudo apt-get update -qq; then
      ok "Working mirror: $mirror"
      return 0
    fi
    warn "Failed: $mirror"
  done
  err "No working Ubuntu mirror found ($tried tried)"
  exit 1
}

main() {
  parse_mirror_args "$@"

  if [[ "$(uname -s)" != "Linux" ]]; then
    err "Linux only"
    exit 1
  fi

  if [[ ! -f /etc/os-release ]]; then
    err "Cannot detect distro (/etc/os-release missing)"
    exit 1
  fi
  # shellcheck disable=SC1091
  . /etc/os-release

  if [[ "$DO_AUTO" -eq 1 ]]; then
    case "${ID:-}" in
      ubuntu|*ubuntu*) probe_ubuntu_mirrors; return ;;
      *)
        err "--auto is currently for Ubuntu only"
        exit 1
        ;;
    esac
  fi

  if [[ -n "$CUSTOM_URL" ]]; then
    IRAN_MIRROR_LABEL="custom URL"
    IRAN_UBUNTU_MIRROR="$CUSTOM_URL"
    case "${ID:-}${ID_LIKE:-}" in
      *ubuntu*|ubuntu) configure_ubuntu_iran ;;
      *)
        err "--url is for Ubuntu sources.list only"
        exit 1
        ;;
    esac
    return
  fi

  if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    local passed=0 a
    for a in "$@"; do
      case "$a" in
        --mirror|--mirror=*|--url|--url=*|--auto) passed=1 ;;
      esac
    done
    if [[ "$passed" -eq 0 && -z "${IRAN_MIRROR:-}" ]]; then
      ask_mirror_interactive
    fi
  fi

  if [[ -n "$CUSTOM_URL" ]]; then
    IRAN_MIRROR_LABEL="custom URL"
    IRAN_UBUNTU_MIRROR="$CUSTOM_URL"
    configure_ubuntu_iran
    return
  fi

  resolve_preset "$MIRROR_ID"

  case "${ID:-}" in
    ubuntu) configure_ubuntu_iran ;;
    debian) configure_debian_iran ;;
    arch) configure_arch_iran ;;
    *)
      case "${ID_LIKE:-}" in
        *ubuntu*) configure_ubuntu_iran ;;
        *debian*) configure_debian_iran ;;
        *arch*) configure_arch_iran ;;
        *)
          err "Unsupported distro: ${ID:-unknown}"
          exit 1
          ;;
      esac
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
