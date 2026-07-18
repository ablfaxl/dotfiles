#!/usr/bin/env bash
# Dotfiles bootstrap — macOS, Ubuntu, Arch
# Usage:
#   ./install.sh
#   ./install.sh --os mac --yes --packages
#   ./install.sh --os ubuntu --yes --packages
#   ./install.sh --os arch --yes --packages
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
WITH_AUR=0
MODULES=()

usage() {
  cat <<'EOF'
Dotfiles installer — portable macOS / Ubuntu / Arch setup

Usage:
  ./install.sh [options]

Options:
  --os <mac|ubuntu|arch|linux>
                     Skip OS prompt (linux is treated as ubuntu)
  --yes, -y          Skip "Proceed?" confirmation (still asks OS unless --os)
  --packages         Install recommended packages for the selected OS
  --aur              On Arch, also install packages/aur.txt via paru/yay
  --no-shell         Do not change the login shell to zsh
  --modules <list>   Comma-separated: core,shell,git,tmux,alacritty,zed,bins,node
                     Default: core,shell,git,tmux,bins,node
  --unlink           Remove symlinks created by this installer
  -h, --help         Show this help

Examples:
  ./install.sh
  ./install.sh --os mac --yes --packages
  ./install.sh --os ubuntu --yes --packages
  ./install.sh --os arch --yes --packages --aur
EOF
}

# Read non-comment, non-empty lines from a package list file into a bash array name.
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
      --aur)
        WITH_AUR=1
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

normalize_os() {
  case "$OS" in
    mac|macos) OS="mac" ;;
    ubuntu|debian|linux) OS="ubuntu" ;;
    arch|archlinux) OS="arch" ;;
    *)
      err "Invalid OS: $OS (use mac, ubuntu, or arch)"
      exit 1
      ;;
  esac
}

ask_os() {
  if [[ -n "$OS" ]]; then
    normalize_os
    info "Using OS from flag: $OS"
    return
  fi

  local detected
  detected="$(detect_os)"
  local hint=""
  if [[ "$detected" == "mac" ]]; then
    hint="macOS"
  elif [[ -f /etc/arch-release ]]; then
    hint="Arch"
  elif [[ -f /etc/os-release ]] && grep -qi ubuntu /etc/os-release 2>/dev/null; then
    hint="Ubuntu"
  elif [[ "$detected" == "linux" ]]; then
    hint="Linux"
  else
    hint="$detected"
  fi

  cat <<EOF

${C_BOLD}Which operating system?${C_RESET}
${C_DIM}Host detected as: ${hint}${C_RESET}

  ${C_CYAN}1)${C_RESET}  macOS
  ${C_CYAN}2)${C_RESET}  Ubuntu
  ${C_CYAN}3)${C_RESET}  Arch Linux

EOF

  local choice=""
  while true; do
    printf 'Select [1/2/3 or mac/ubuntu/arch]: '
    read -r choice || true
    case "${choice}" in
      1|mac|macos|Mac|MAC|m|M)
        OS="mac"
        break
        ;;
      2|ubuntu|Ubuntu|debian|linux|Linux)
        OS="ubuntu"
        break
        ;;
      3|arch|Arch|archlinux)
        OS="arch"
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
    MODULES=(core shell git tmux bins node)
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
  local pkgs=()
  read_pkg_list "$DOTFILES_ROOT/packages/brew.txt" pkgs
  if ((${#pkgs[@]})); then
    step "Installing Homebrew packages (${#pkgs[@]})"
    brew install "${pkgs[@]}"
  fi
  local casks=()
  read_pkg_list "$DOTFILES_ROOT/packages/brew-casks.txt" casks
  if ((${#casks[@]})); then
    step "Installing Homebrew casks (${#casks[@]})"
    brew install --cask "${casks[@]}" || true
  fi
  ok "macOS packages installed"
  info "Start Docker runtime with: colima start"
}

install_packages_ubuntu() {
  local pkgs=()
  local missing=()
  local p
  read_pkg_list "$DOTFILES_ROOT/packages/apt.txt" pkgs
  step "Installing apt packages (${#pkgs[@]}) — root/sudo required"
  run_root apt-get update

  # Skip packages unavailable on this Ubuntu release (keeps install resilient)
  for p in "${pkgs[@]}"; do
    if apt-cache show "$p" >/dev/null 2>&1; then
      continue
    fi
    missing+=("$p")
  done
  if ((${#missing[@]})); then
    warn "Skipping unavailable packages: ${missing[*]}"
    local filtered=()
    for p in "${pkgs[@]}"; do
      local skip=0 m
      for m in "${missing[@]}"; do
        [[ "$p" == "$m" ]] && skip=1 && break
      done
      [[ "$skip" -eq 0 ]] && filtered+=("$p")
    done
    pkgs=("${filtered[@]}")
  fi

  if ((${#pkgs[@]})); then
    run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}"
  else
    warn "No apt packages left to install"
  fi

  # Ubuntu fd/bat binary names
  mkdir -p "$HOME/.local/bin"
  if command_exists fdfind && ! command_exists fd; then
    ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
    ok "Linked fdfind -> ~/.local/bin/fd"
  fi
  if command_exists batcat && ! command_exists bat; then
    ln -sfn "$(command -v batcat)" "$HOME/.local/bin/bat"
    ok "Linked batcat -> ~/.local/bin/bat"
  fi

  # git-lfs (optional but listed)
  if command_exists git-lfs; then
    git lfs install --skip-repo >/dev/null 2>&1 || true
    ok "git-lfs hooks installed"
  fi

  if command_exists docker; then
    run_root usermod -aG docker "$USER" 2>/dev/null || true
    # Prefer enabling the daemon on desktop/server Ubuntu
    if command_exists systemctl; then
      run_root systemctl enable --now docker 2>/dev/null || true
    fi
    warn "Log out/in for docker group membership to apply"
  fi
  ok "Ubuntu packages installed"
}

install_packages_arch() {
  local pkgs=()
  read_pkg_list "$DOTFILES_ROOT/packages/pacman.txt" pkgs
  step "Installing pacman packages (${#pkgs[@]}) — root/sudo required"
  run_root pacman -Syu --needed --noconfirm "${pkgs[@]}"

  if command_exists docker; then
    run_root systemctl enable --now docker 2>/dev/null || true
    run_root usermod -aG docker "$USER" 2>/dev/null || true
    warn "Log out/in for docker group membership to apply"
  fi

  if [[ "$WITH_AUR" -eq 1 ]]; then
    local helper=""
    if command_exists paru; then helper=paru
    elif command_exists yay; then helper=yay
    fi
    if [[ -z "$helper" ]]; then
      warn "No AUR helper (paru/yay) found — skip packages/aur.txt"
    else
      local aur=()
      read_pkg_list "$DOTFILES_ROOT/packages/aur.txt" aur
      if ((${#aur[@]})); then
        step "Installing AUR packages via $helper (${#aur[@]})"
        "$helper" -S --needed --noconfirm "${aur[@]}"
      else
        info "packages/aur.txt is empty — nothing to install"
      fi
    fi
  fi
  ok "Arch packages installed"
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
  link_file "$DOTFILES_ROOT/config/starship.toml" "$HOME/.config/starship.toml"
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
  # On Ubuntu/GNOME, make Alacritty the system default terminal when possible
  if [[ "$OS" == "ubuntu" ]] && command_exists alacritty; then
    if command_exists gsettings; then
      gsettings set org.gnome.desktop.default-applications.terminal exec 'alacritty' 2>/dev/null || true
      gsettings set org.gnome.desktop.default-applications.terminal exec-arg '-e' 2>/dev/null || true
      ok "GNOME default terminal → alacritty"
    fi
    if [[ -x /usr/bin/alacritty ]] && command_exists update-alternatives; then
      run_root update-alternatives --set x-terminal-emulator /usr/bin/alacritty 2>/dev/null \
        || warn "Run: sudo update-alternatives --set x-terminal-emulator /usr/bin/alacritty"
    fi
  fi
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

install_node_toolchain() {
  step "Node / React / JS toolchain (fnm + ni/nr + globals)"
  chmod +x "$DOTFILES_ROOT/scripts/install-node-toolchain.sh"
  "$DOTFILES_ROOT/scripts/install-node-toolchain.sh"
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
      echo "$zsh_path" | run_root tee -a /etc/shells >/dev/null
    fi
    if [[ "$(id -u)" -eq 0 ]]; then
      # chsh as root against $USER when HOME belongs to a normal account
      if [[ -n "${USER:-}" && "$USER" != "root" ]] && id "$USER" >/dev/null 2>&1; then
        run_root chsh -s "$zsh_path" "$USER" || true
      else
        warn "Running as root — skip chsh (set login shell for your user manually)"
      fi
    else
      chsh -s "$zsh_path"
    fi
    ok "Login shell set to $zsh_path (re-login to apply)"
  fi
}

ensure_omz_plugins() {
  local custom="$HOME/.config/oh-my-zsh/custom/plugins"
  ensure_dir "$custom"

  ensure_git_plugin() {
    local name="$1"
    local url="$2"
    if [[ -d "$custom/$name/.git" ]]; then
      ok "Plugin present: $name"
      return 0
    fi
    info "Installing plugin: $name"
    rm -rf "$custom/$name"
    git clone --depth 1 "$url" "$custom/$name"
    ok "Installed plugin: $name"
  }

  ensure_git_plugin zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions
  ensure_git_plugin zsh-completions https://github.com/zsh-users/zsh-completions
  ensure_git_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting
  # history-substring-search is bundled with oh-my-zsh (plugins/history-substring-search)
}

install_omz_optional() {
  # Treat missing oh-my-zsh.sh as broken (empty dir with only custom/ plugins)
  if [[ ! -f "$HOME/.config/oh-my-zsh/oh-my-zsh.sh" ]]; then
    if [[ -d "$HOME/.config/oh-my-zsh" ]]; then
      warn "oh-my-zsh looks broken (missing oh-my-zsh.sh) — repairing"
      local custom_bak=""
      if [[ -d "$HOME/.config/oh-my-zsh/custom" ]]; then
        custom_bak="$(mktemp -d)"
        cp -a "$HOME/.config/oh-my-zsh/custom/." "$custom_bak/" 2>/dev/null || true
      fi
      rm -rf "$HOME/.config/oh-my-zsh"
      info "Cloning oh-my-zsh into ~/.config/oh-my-zsh ..."
      git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.config/oh-my-zsh"
      if [[ -n "$custom_bak" ]]; then
        mkdir -p "$HOME/.config/oh-my-zsh/custom"
        cp -a "$custom_bak/." "$HOME/.config/oh-my-zsh/custom/" 2>/dev/null || true
        rm -rf "$custom_bak"
      fi
      ok "oh-my-zsh repaired"
    elif [[ "$ASSUME_YES" -eq 1 ]] || confirm "Install oh-my-zsh into ~/.config/oh-my-zsh?"; then
      info "Cloning oh-my-zsh..."
      git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.config/oh-my-zsh"
      ok "oh-my-zsh installed"
    else
      warn "Skipping oh-my-zsh install (geek prompt still works)"
      return
    fi
  else
    ok "oh-my-zsh already present"
  fi

  step "Ensuring oh-my-zsh plugins"
  ensure_omz_plugins
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
    "$HOME/.config/starship.toml"
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

${C_CYAN}${C_BOLD}
    ╔══════════════════════════════════════════════╗
    ║   ▓▓▓  DOTFILES  ·  DEVOPS COCKPIT  ▓▓▓      ║
    ║   macOS  ·  Ubuntu  ·  Arch                  ║
    ║   shell · git · tmux · bins · packages       ║
    ╚══════════════════════════════════════════════╝
${C_RESET}
  ${C_DIM}repo${C_RESET}  $DOTFILES_ROOT
  ${C_DIM}host${C_RESET}  $(uname -sr 2>/dev/null || echo unknown)
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
      ubuntu) install_packages_ubuntu ;;
      arch) install_packages_arch ;;
    esac
  fi

  has_module core && link_core
  has_module shell && link_shell && install_omz_optional
  has_module git && link_git
  has_module tmux && link_tmux
  has_module alacritty && link_alacritty
  has_module zed && link_zed
  has_module bins && link_bins
  has_module node && install_node_toolchain

  setup_shell

  cat <<EOF

${C_GREEN}${C_BOLD}Install complete.${C_RESET}

Next steps:
  1. Set git identity   ${C_DIM}nvim ~/.config/git/config.local${C_RESET}
  2. Reload your shell  ${C_DIM}exec zsh -l${C_RESET}
  3. Install tmux plugins inside tmux: ${C_DIM}prefix + I${C_RESET}  (Ctrl-a then Shift-i)
  4. Validate apps      ${C_DIM}./scripts/validate-apps.sh${C_RESET}

Docs: ${C_DIM}APPS.md${C_RESET}

Optional:
  ./install.sh --os $OS --modules alacritty,zed
  ./install.sh --os $OS --packages
  make node                 ${C_DIM}# fnm + Node LTS + ni/nr + JS globals${C_RESET}

EOF
}

main "$@"
