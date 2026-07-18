#!/usr/bin/env bash
# Install Node.js toolchain for frontend + backend JS/React (all OS).
# Uses fnm (Fast Node Manager) so versions stay consistent on macOS / Ubuntu / Arch.
#
# Installs:
#   - fnm + Node LTS
#   - corepack → pnpm + yarn
#   - bun (optional, best-effort)
#   - packages/npm-globals.txt  (@antfu/ni → ni/nr/nlx, tsx, …)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$ROOT/lib/common.sh"

NODE_VERSION="${NODE_VERSION:-lts-latest}"
FNM_DIR="${FNM_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/fnm}"
SKIP_BUN="${SKIP_BUN:-0}"

ensure_fnm() {
  if command_exists fnm; then
    ok "fnm already installed ($(fnm --version 2>/dev/null || echo ok))"
    return 0
  fi
  if [[ -x "$FNM_DIR/fnm" ]]; then
    prepend_path() { case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH" ;; esac; }
    prepend_path "$FNM_DIR"
    export PATH
    ok "fnm found in $FNM_DIR"
    return 0
  fi

  step "Installing fnm into $FNM_DIR"
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$FNM_DIR" --skip-shell
  export PATH="$FNM_DIR:$PATH"
  ok "fnm installed"
}

init_fnm_env() {
  export PATH="$FNM_DIR:$PATH"
  eval "$(fnm env --use-on-cd --shell bash)"
}

ensure_node() {
  init_fnm_env
  if command_exists node && node -v >/dev/null 2>&1; then
    ok "node $(node -v) / npm $(npm -v)"
  else
    step "Installing Node.js ($NODE_VERSION) via fnm"
    fnm install "$NODE_VERSION"
    fnm default "$NODE_VERSION"
    eval "$(fnm env --use-on-cd --shell bash)"
    ok "node $(node -v) / npm $(npm -v)"
  fi
}

ensure_corepack_pnpm_yarn() {
  if command_exists corepack; then
    step "Enabling corepack (pnpm + yarn)"
    corepack enable >/dev/null 2>&1 || true
    corepack prepare pnpm@latest --activate >/dev/null 2>&1 || true
    corepack prepare yarn@stable --activate >/dev/null 2>&1 || true
  fi
  # Fallbacks
  if ! command_exists pnpm; then
    npm install -g pnpm >/dev/null 2>&1 || warn "pnpm install failed"
  fi
  if ! command_exists yarn; then
    npm install -g yarn >/dev/null 2>&1 || warn "yarn install failed"
  fi
  command_exists pnpm && ok "pnpm $(pnpm -v)"
  command_exists yarn && ok "yarn $(yarn -v 2>/dev/null | head -1)"
}

ensure_bun() {
  [[ "$SKIP_BUN" == "1" ]] && return 0
  if command_exists bun; then
    ok "bun $(bun -v)"
    return 0
  fi
  step "Installing bun (best-effort)"
  if curl -fsSL https://bun.sh/install | bash; then
    export BUN_INSTALL="${XDG_DATA_HOME:-$HOME/.local/share}/bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
    command_exists bun && ok "bun $(bun -v)" || warn "bun installed but not on PATH yet"
  else
    warn "bun install skipped/failed"
  fi
}

install_npm_globals() {
  local list="$ROOT/packages/npm-globals.txt"
  local pkgs=() line
  [[ -f "$list" ]] || { warn "No $list"; return 0; }
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line//[[:space:]]/}" ]] && continue
    pkgs+=("$line")
  done <"$list"
  ((${#pkgs[@]})) || return 0

  step "Installing npm globals (${#pkgs[@]}) — includes @antfu/ni (ni/nr/nlx)"
  npm install -g "${pkgs[@]}"
  ok "npm globals installed"
  command_exists ni && ok "ni ready ($(ni --version 2>/dev/null || echo @antfu/ni))"
}

# Stable shims in ~/.local/bin so Alacritty non-login shells always find pnpm/node
link_node_shims() {
  local bin="$HOME/.local/bin"
  local node_bin=""
  mkdir -p "$bin" "${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"

  if command_exists node; then
    node_bin="$(cd "$(dirname "$(command -v node)")" && pwd -P 2>/dev/null || dirname "$(command -v node)")"
  fi
  # Prefer permanent fnm install path over ephemeral multishell
  if [[ "$node_bin" == *fnm_multishells* ]] || [[ -z "$node_bin" ]]; then
    local cand
    cand="$(ls -d "${FNM_DIR:-$HOME/.local/share/fnm}"/node-versions/*/installation/bin 2>/dev/null | sort -V | tail -1 || true)"
    [[ -n "$cand" ]] && node_bin="$cand"
  fi
  [[ -n "$node_bin" ]] || { warn "No node bin to shim"; return 0; }

  step "Linking Node shims into ~/.local/bin"
  local cmd
  for cmd in node npm npx pnpm yarn ni nr nlx nun tsx corepack; do
    if [[ -x "$node_bin/$cmd" ]]; then
      ln -sfn "$node_bin/$cmd" "$bin/$cmd"
    fi
  done
  if [[ -x "${BUN_INSTALL:-$HOME/.local/share/bun}/bin/bun" ]]; then
    ln -sfn "${BUN_INSTALL:-$HOME/.local/share/bun}/bin/bun" "$bin/bun"
  fi
  [[ -x "$node_bin/pnpm" ]] && ln -sfn "$node_bin/pnpm" "${XDG_DATA_HOME:-$HOME/.local/share}/pnpm/pnpm"
  ok "shims: node npm pnpm yarn ni nr → ~/.local/bin"
}

print_summary() {
  cat <<EOF

${C_GREEN}${C_BOLD}Node toolchain ready.${C_RESET}

  node    $(command -v node >/dev/null && node -v || echo missing)
  npm     $(command -v npm >/dev/null && npm -v || echo missing)
  pnpm    $(command -v pnpm >/dev/null && pnpm -v || echo missing)
  yarn    $(command -v yarn >/dev/null && yarn -v 2>/dev/null | head -1 || echo missing)
  bun     $(command -v bun >/dev/null && bun -v || echo optional)
  ni/nr   $(command -v ni >/dev/null && echo ok || echo missing)

Reload shell:  ${C_DIM}exec zsh -l${C_RESET}

Quick React / Node:
  ni                 # install deps (auto npm/pnpm/yarn/bun)
  nr dev             # run script
  nr build
  nlx create-vite@latest my-app -- --template react-ts
  fnm use 22         # switch Node version
  fnm install 20

EOF
}

main() {
  step "JS / Node / React toolchain"
  ensure_fnm
  ensure_node
  ensure_corepack_pnpm_yarn
  ensure_bun
  install_npm_globals
  link_node_shims
  print_summary
}

main "$@"
