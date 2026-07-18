#!/usr/bin/env bash
# Install only the Ubuntu apt packages from packages/apt.txt
# Useful when the main installer already linked configs but sudo was unavailable.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$ROOT/lib/common.sh"

pkgs=()
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${line//[[:space:]]/}" ]] && continue
  pkgs+=("$line")
done <"$ROOT/packages/apt.txt"

step "Ubuntu apt packages (${#pkgs[@]})"
run_root apt-get update
run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}"

mkdir -p "$HOME/.local/bin"
if command_exists fdfind && ! command_exists fd; then
  ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
  ok "Linked fdfind -> ~/.local/bin/fd"
fi
if command_exists batcat && ! command_exists bat; then
  ln -sfn "$(command -v batcat)" "$HOME/.local/bin/bat"
  ok "Linked batcat -> ~/.local/bin/bat"
fi
if command_exists git-lfs; then
  git lfs install --skip-repo >/dev/null 2>&1 || true
fi
if command_exists docker; then
  run_root usermod -aG docker "$USER" 2>/dev/null || true
  run_root systemctl enable --now docker 2>/dev/null || true
fi
ok "Done — run: ./scripts/validate-apps.sh"
