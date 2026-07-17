#!/usr/bin/env bash
# Dotfiles bootstrap — macOS & Linux
# Usage:
#   ./install.sh              # interactive
#   ./install.sh --os mac
#   ./install.sh --os linux
#   ./install.sh --os mac --yes --packages
#   ./install.sh --unlink

set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$DOTFILES_ROOT/lib/common.sh"

OS=""
ASSUME_YES=0
INSTALL_PACKAGES=0
SKIP_SHELL=0
UNLINK=0
MODULES=()

usage() {
  cat <<'EOF'
Dotfiles installer — portable macOS & Linux setup

Usage:
  ./install.sh [options]

Options:
  --os <mac|linux>   Skip OS prompt and use this value
  --yes, -y          Skip "Proceed?" confirmation (still asks OS unless --os)
  --packages         Install CLI packages (Homebrew / apt)
  --no-shell         Do not change the login shell to zsh
  --modules <list>   Comma-separated: core,shell,git,tmux,alacritty,zed,bins
                     Default: core,shell,git,tmux,bins
  --unlink           Remove symlinks created by this installer
  -h, --help         Show this help

Examples:
  ./install.sh
  ./install.sh --os mac --yes --packages
  ./install.sh --os linux --modules core,shell,git,bins
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --os)
        OS="$2"
        shift 2
        ;;
      --yes|-y)
        ASSUME_YES=1
        shift
        ;;
      --packages)
        INSTALL_PACKAGES=1
        shift
        ;;
      --no-shell)
        SKIP_SHELL=1
        shift
        ;;
      --modules)
        IFS=',' read -r -a MODULES <<<"$2"
        shift 2
        ;;
      --unlink)
        UNLINK=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        err "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
  done
}

ask_os() {
  # Only skip the prompt when user already passed --os
  if [[ -n "$OS" ]]; then
    case "$OS" in
      mac|linux) ;;
      *)
        err "Invalid --os value: $OS (use mac or linux)"
        exit 1
        ;;
    esac
    info "Using OS from flag: $OS"
    return
  fi

  local detected
  detected="$(detect_os)"

  cat <<EOF

${C_BOLD}Which operating system?${C_RESET}
${C_DIM}Host detected as: ${detected}${C_RESET}

  ${C_CYAN}1)${C_RESET}  macOS
  ${C_CYAN}2)${C_RESET}  Linux

EOF

  local choice=""
  while true; do
    printf 'Select [1/2 or mac/linux]: '
    read -r choice || true
    case "${choice}" in
      1|mac|macos|Mac|MAC|m|M)
        OS="mac"
        break
        ;;
      2|linux|Linux|LINUX|l|L)
        OS="linux"
        break
        ;;
      "")
        warn "Please choose an option (empty input is not allowed)"
        ;;
      *)
        warn "Invalid choice: '${choice}' - try again"
        ;;
    esac
  done

  ok "OS set to: $OS"
}

default_modules() {
  if [[ ${#MODULES[@]} -eq 0 ]]; then
    MODULES=(core shell git tmux bins)
  fi
}

has_module() {
  local m
  for m in "${MODULES[@]}"; do
    [[ "$m" == "$1" || "$m" == "all" ]] && return 0
  done
  return 1
}

ensure_homebrew() {
  if command_exists brew; then
    ok "Homebrew already installed"
    return
  fi
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_packages_mac() {
  ensure_homebrew
  step "Installing Homebrew packages"
  # shellcheck disable=SC2046
  brew install $(grep -vE '^\s*#|^\s*$' "$DOTFILES_ROOT/packages/brew.txt" | tr '\n' ' ')
  if [[ -f "$DOTFILES_ROOT/packages/brew-casks.txt" ]]; then
    step "Installing Homebrew casks"
    # shellcheck disable=SC2046
    brew install --cask $(grep -vE '^\s*#|^\s*$' "$DOTFILES_ROOT/packages/brew-casks.txt" | tr '\n' ' ') || true
  fi
}

install_packages_linux() {
  step "Installing apt packages (sudo)"
  sudo apt-get update
  # shellcheck disable=SC2046
  sudo apt-get install -y $(grep -vE '^\s*#|^\s*$' "$DOTFILES_ROOT/packages/apt.txt" | tr '\n' ' ')
}

link_core() {
  step "Linking core XDG configs"
  ensure_dir "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share" "$HOME/.cache"

  link_file "$DOTFILES_ROOT/config/env" "$HOME/.config/env"
  link_file "$DOTFILES_ROOT/config/aliasrc" "$HOME/.config/aliasrc"
  link_file "$DOTFILES_ROOT/config/inputrc" "$HOME/.config/inputrc"
  link_file "$DOTFILES_ROOT/home/zprofile" "$HOME/.zprofile"
  link_file "$DOTFILES_ROOT/home/zshenv" "$HOME/.zshenv"

  link_file "$DOTFILES_ROOT/config/ripgrep" "$HOME/.config/ripgrep"
  link_file "$DOTFILES_ROOT/config/npm" "$HOME/.config/npm"
  link_file "$DOTFILES_ROOT/config/wget" "$HOME/.config/wget"
  link_file "$DOTFILES_ROOT/config/gh" "$HOME/.config/gh"
}

link_shell() {
  step "Linking zsh"
  link_file "$DOTFILES_ROOT/config/zsh" "$HOME/.config/zsh"
}

link_git() {
  step "Linking git"
  link_file "$DOTFILES_ROOT/config/git" "$HOME/.config/git"
  if [[ ! -f "$HOME/.config/git/config.local" ]]; then
    cp "$DOTFILES_ROOT/config/git/config.local.example" "$HOME/.config/git/config.local"
    warn "Edit ~/.config/git/config.local with your name/email"
  fi
}

link_tmux() {
  step "Linking tmux"
  link_file "$DOTFILES_ROOT/config/tmux" "$HOME/.config/tmux"
  if [[ ! -d "$HOME/.config/tmux/plugins/tpm" ]]; then
    info "Installing TPM (tmux plugin manager)..."
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
  fi
}

link_alacritty() {
  step "Linking Alacritty"
  link_file "$DOTFILES_ROOT/config/alacritty" "$HOME/.config/alacritty"
}

link_zed() {
  step "Linking Zed"
  link_file "$DOTFILES_ROOT/config/zed" "$HOME/.config/zed"
}

link_bins() {
  step "Linking utility scripts to ~/.local/bin"
  local script dest
  for script in "$DOTFILES_ROOT"/bin/*; do
    [[ -f "$script" ]] || continue
    dest="$HOME/.local/bin/$(basename "$script")"
    link_file "$script" "$dest"
    chmod +x "$script"
  done
}

setup_shell() {
  [[ "$SKIP_SHELL" -eq 1 ]] && return
  if ! command_exists zsh; then
    warn "zsh not found - skipping login shell change"
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

install_omz_optional() {
  if [[ -d "$HOME/.config/oh-my-zsh" ]]; then
    ok "oh-my-zsh already present"
    return
  fi
  if [[ "$ASSUME_YES" -eq 1 ]] || confirm "Install oh-my-zsh into ~/.config/oh-my-zsh?"; then
    info "Installing oh-my-zsh..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes ZSH="$HOME/.config/oh-my-zsh" \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    # Popular plugins
    local custom="$HOME/.config/oh-my-zsh/custom/plugins"
    ensure_dir "$custom"
    [[ -d "$custom/zsh-autosuggestions" ]] || \
      git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$custom/zsh-autosuggestions"
    [[ -d "$custom/zsh-completions" ]] || \
      git clone --depth 1 https://github.com/zsh-users/zsh-completions "$custom/zsh-completions"
    [[ -d "$custom/zsh-history-substring-search" ]] || \
      git clone --depth 1 https://github.com/zsh-users/zsh-history-substring-search "$custom/zsh-history-substring-search"
    ok "oh-my-zsh + plugins installed"
  fi
}

do_unlink() {
  step "Removing managed symlinks"
  local targets=(
    "$HOME/.zprofile"
    "$HOME/.zshenv"
    "$HOME/.config/env"
    "$HOME/.config/aliasrc"
    "$HOME/.config/inputrc"
    "$HOME/.config/zsh"
    "$HOME/.config/git"
    "$HOME/.config/tmux"
    "$HOME/.config/alacritty"
    "$HOME/.config/zed"
    "$HOME/.config/ripgrep"
    "$HOME/.config/npm"
    "$HOME/.config/wget"
    "$HOME/.config/gh"
  )
  local t
  for t in "${targets[@]}"; do
    if [[ -L "$t" ]]; then
      rm -f "$t"
      ok "Removed $t"
    fi
  done
  for t in "$HOME"/.local/bin/*; do
    [[ -L "$t" ]] || continue
    local link
    link="$(readlink "$t")"
    if [[ "$link" == "$DOTFILES_ROOT/bin/"* ]]; then
      rm -f "$t"
      ok "Removed $t"
    fi
  done
}

print_banner() {
  cat <<EOF

${C_CYAN}${C_BOLD}┌──────────────────────────────────────────────┐
│  Dotfiles · macOS & Linux bootstrap          │
│  Clean portable developer setup              │
└──────────────────────────────────────────────┘${C_RESET}

  ${C_DIM}repo${C_RESET}  $DOTFILES_ROOT
EOF
}

main() {
  parse_args "$@"
  print_banner

  if [[ "$UNLINK" -eq 1 ]]; then
    do_unlink
    exit 0
  fi

  ask_os
  default_modules

  info "OS: $OS"
  info "Modules: ${MODULES[*]}"
  info "Packages: $([[ "$INSTALL_PACKAGES" -eq 1 ]] && echo yes || echo no)"

  if [[ "$ASSUME_YES" -ne 1 ]]; then
    confirm "Proceed with install?" || { warn "Aborted"; exit 0; }
  fi

  if [[ "$INSTALL_PACKAGES" -eq 1 ]]; then
    case "$OS" in
      mac) install_packages_mac ;;
      linux) install_packages_linux ;;
    esac
  fi

  has_module core && link_core
  has_module shell && link_shell && install_omz_optional
  has_module git && link_git
  has_module tmux && link_tmux
  has_module alacritty && link_alacritty
  has_module zed && link_zed
  has_module bins && link_bins

  setup_shell

  cat <<EOF

${C_GREEN}${C_BOLD}Install complete.${C_RESET}

Next steps:
  1. Set git identity   ${C_DIM}nvim ~/.config/git/config.local${C_RESET}
  2. Reload your shell  ${C_DIM}exec zsh -l${C_RESET}
  3. Install tmux plugins inside tmux: ${C_DIM}prefix + I${C_RESET}  (Ctrl-a then Shift-i)

Optional:
  ./install.sh --os $OS --modules alacritty,zed
  ./install.sh --os $OS --packages

EOF
}

main "$@"
