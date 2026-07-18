#!/usr/bin/env bash
# Validate that recommended apps are available on PATH.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$ROOT/lib/common.sh"

pass=0
fail=0
skip=0

check_cmd() {
  local name="$1"
  local alt="${2:-}"
  if command_exists "$name"; then
    local ver
    ver="$("$name" --version 2>/dev/null | head -1 || "$name" -V 2>/dev/null | head -1 || echo "installed")"
    ok "$name  ($ver)"
    pass=$((pass + 1))
    return 0
  fi
  if [[ -n "$alt" ]] && command_exists "$alt"; then
    ok "$name via $alt  ($("$alt" --version 2>/dev/null | head -1 || echo installed))"
    pass=$((pass + 1))
    return 0
  fi
  err "missing: $name${alt:+ (or $alt)}"
  fail=$((fail + 1))
  return 1
}

check_optional() {
  local name="$1"
  if command_exists "$name"; then
    ok "$name (optional)"
    pass=$((pass + 1))
  else
    warn "optional not found: $name"
    skip=$((skip + 1))
  fi
}

step "Core toolchain"
check_cmd zsh
check_cmd git
check_cmd nvim vim
check_cmd tmux
check_cmd rg
check_cmd fzf
check_cmd fd fdfind
check_cmd bat batcat
check_cmd eza
check_cmd jq

step "Geek extras"
check_optional btop
check_optional zoxide
check_optional duf
check_optional shellcheck
check_optional ncdu
check_optional httpie
check_optional tldr

step "Git extras"
check_optional gh
check_optional lazygit
check_optional delta
check_optional git-lfs

step "Terminal / containers"
check_optional alacritty
check_optional docker
check_optional colima

step "Node / JS / React"
check_optional fnm
check_optional node
check_optional npm
check_optional pnpm
check_optional yarn
check_optional bun
check_optional ni
check_optional nr
check_optional tsx

echo
info "Results: ${pass} ok, ${fail} missing, ${skip} optional-skipped"
if ((fail > 0)); then
  exit 1
fi
exit 0
