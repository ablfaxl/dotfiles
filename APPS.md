# Recommended apps (default profile)

Assumptions used after you said **go on**:

- Profile: **software development** + light productivity
- Style: **CLI-first**, small GUI set
- Platforms: **macOS**, **Ubuntu**, **Arch**
- Package managers: Homebrew / apt / pacman (optional AUR notes)

---

## Priority apps (4–6 per platform)

### macOS

| # | App | Why |
|---|-----|-----|
| 1 | **Alacritty** | Fast GPU terminal; configs already in this repo |
| 2 | **Neovim** | Primary editor; pairs with your `EDITOR`/`aliasrc` |
| 3 | **tmux** | Persistent sessions; TPM-ready config included |
| 4 | **Git toolkit** (`git`, `git-delta`, `gh`, `lazygit`) | Everyday VCS with readable diffs + GitHub CLI |
| 5 | **Search suite** (`fzf`, `fd`, `ripgrep`, `bat`, `eza`) | Fast find/preview/list workflow |
| 6 | **Docker via Colima** | Containers without heavy Docker Desktop |

### Ubuntu

| # | App | Why |
|---|-----|-----|
| 1 | **Alacritty** | Same terminal experience as macOS |
| 2 | **Neovim** | Cross-platform editor default |
| 3 | **tmux** | Session manager |
| 4 | **Git toolkit** (`git`, `gh`, optional `git-delta` via cargo/brew) | Core VCS + GitHub |
| 5 | **Search suite** (`fzf`, `fd-find`, `ripgrep`, `bat`, `eza`) | Same habits as macOS |
| 6 | **Docker Engine** + Compose plugin | Standard Linux container stack |

### Arch

| # | App | Why |
|---|-----|-----|
| 1 | **Alacritty** | Official repos; first-class packaging |
| 2 | **Neovim** | Rolling, always current |
| 3 | **tmux** | Session manager |
| 4 | **Git toolkit** (`git`, `github-cli`, `git-delta`, `lazygit`) | Full set in official/community |
| 5 | **Search suite** (`fzf`, `fd`, `ripgrep`, `bat`, `eza`) | Native package names |
| 6 | **Docker** + Compose | Official packages; enable systemd unit |

---

## Install commands

### One-shot (this repo)

```bash
# Interactive: asks macOS / Ubuntu / Arch
./install.sh --packages

# Explicit
./install.sh --os mac --yes --packages
./install.sh --os ubuntu --yes --packages
./install.sh --os arch --yes --packages
```

### macOS (Homebrew)

```bash
# CLI
brew install $(grep -vE '^\s*#|^\s*$' packages/brew.txt | tr '\n' ' ')

# GUI / fonts
brew install --cask $(grep -vE '^\s*#|^\s*$' packages/brew-casks.txt | tr '\n' ' ')
```

### Ubuntu (apt)

```bash
sudo apt-get update
sudo apt-get install -y $(grep -vE '^\s*#|^\s*$' packages/apt.txt | tr '\n' ' ')

# Optional: Docker (official convenience script or apt docker.io)
sudo apt-get install -y docker.io docker-compose-v2
sudo usermod -aG docker "$USER"
```

### Arch (pacman)

```bash
sudo pacman -Syu --needed --noconfirm $(grep -vE '^\s*#|^\s*$' packages/pacman.txt | tr '\n' ' ')

# Optional AUR (paru/yay) — see packages/aur.txt
# paru -S --needed --noconfirm $(grep -vE '^\s*#|^\s*$' packages/aur.txt | tr '\n' ' ')
```

---

## Validation

```bash
./scripts/validate-apps.sh
```

Or manually:

```bash
nvim --version | head -1
tmux -V
alacritty --version
rg --version
fzf --version
git --version
gh --version
docker version   # after daemon is running
```

Ubuntu note: `fd` may be installed as `fdfind` — the validator checks both.

---

## Minimal config (already in this repo)

| App | Config path | Defaults |
|-----|-------------|----------|
| Alacritty | `config/alacritty/` | Dark theme, JetBrainsMono NF, vi mode |
| Neovim | system / your nvim config | `EDITOR=nvim` via `config/env` |
| tmux | `config/tmux/tmux.conf` | Prefix `Ctrl-a`, mouse, TPM |
| git | `config/git/` | delta pager, rebase pull, aliases |
| ripgrep | `config/ripgrep/config` | hidden files, sensible ignores |
| gh | `config/gh/config.yml` | `gh co` → `pr checkout` |

After install:

```bash
nvim ~/.config/git/config.local   # name + email
exec zsh -l
# in tmux: Ctrl-a then Shift-i
```
