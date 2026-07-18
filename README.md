<!-- @format -->

# Dotfiles

> Quick start (FA): [QUICKSTART.fa.md](./QUICKSTART.fa.md) · Apps plan: [APPS.md](./APPS.md)

Portable **macOS / Ubuntu / Arch** developer environment.

Linux-only desktop stacks (Hyprland, i3, polybar, awesome, …) were intentionally left out. What remains is shell, git, tmux, terminal, and everyday CLI tooling — with a one-command installer.

---

## Quick start

```bash
git clone <YOUR_REPO_URL> ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

Installer asks **macOS / Ubuntu / Arch**, then links configs and optionally installs packages.

See the full app plan, install commands, and validation in **[APPS.md](./APPS.md)**.

### One-liners

```bash
# macOS — full setup
./install.sh --os mac --yes --packages --modules core,shell,git,tmux,alacritty,bins

# Ubuntu
./install.sh --os ubuntu --yes --packages --modules core,shell,git,tmux,alacritty,bins
# packages only (sudo): make ubuntu-packages


# Arch
./install.sh --os arch --yes --packages --modules core,shell,git,tmux,alacritty,bins

# Or via Make
make mac
make ubuntu
make arch

# Validate tooling
make validate

# Linux server shell (Debian/Ubuntu or Arch) — lightweight SSH setup
./scripts/setup-server-shell.sh --yes
# or: make server
```

After install:

```bash
# 1) set your git identity
nvim ~/.config/git/config.local

# 2) reload shell
exec zsh -l

# 3) inside tmux: install plugins
#    prefix (Ctrl-a) then Shift-i

# 4) confirm apps
./scripts/validate-apps.sh
```

---

## What you get

| Area          | Contents                                                             |
| ------------- | -------------------------------------------------------------------- |
| **Shell**     | XDG-clean `env`, zsh + oh-my-zsh plugins, **geek prompt** (or Starship) |
| **Git**       | aliases, delta pager, sensible defaults — identity in `config.local` |
| **Tmux**      | prefix `Ctrl-a`, vim panes, TPM plugins                              |
| **Alacritty** | modular theme (Mac / Linux)                                          |
| **Bins**      | `killport`, `port`, `ex`, `localip`, `ffd`, `renpm`, `cpwd`, …       |
| **Packages**  | Homebrew / apt lists under `packages/`                               |

### Layout

```
.
├── install.sh          # interactive bootstrap
├── Makefile
├── config/             # → ~/.config/...
│   ├── env
│   ├── aliasrc
│   ├── zsh/
│   ├── git/
│   ├── tmux/
│   ├── alacritty/
│   └── …
├── home/zprofile       # → ~/.zprofile
├── bin/                # → ~/.local/bin/
└── packages/           # brew.txt · brew-casks.txt · apt.txt
```

---

## Modules

```bash
./install.sh --modules core,shell,git,tmux,bins
./install.sh --modules alacritty,zed    # optional extras
```

| Module      | Links                                                      |
| ----------- | ---------------------------------------------------------- |
| `core`      | env, aliases, inputrc, ripgrep, npm, wget, gh, `.zprofile` |
| `shell`     | zsh + optional oh-my-zsh                                   |
| `git`       | git config + ignore                                        |
| `tmux`      | tmux + TPM                                                 |
| `alacritty` | Alacritty                                                  |
| `zed`       | Zed editor                                                 |
| `bins`      | `~/.local/bin` scripts                                     |

---

## Uninstall / re-link

```bash
./install.sh --unlink    # remove managed symlinks (keeps backups *.bak.*)
./install.sh --os mac    # link again
```

Existing files are renamed to `*.bak.TIMESTAMP` before linking.

---

## Notes

- **Personal data** from the upstream repo (email, GPG, SSH hosts, Arch/Hyprland) is not included.
- Put machine-specific overrides in:
  - `~/.config/git/config.local`
  - `~/.config/zsh/local.zsh`
- On Apple Silicon, Homebrew is expected at `/opt/homebrew`.
- Font default for Alacritty/Zed: **JetBrainsMono Nerd Font** (installed via brew cask list).

---

## Credit

Heavily inspired by [ /dotfiles](https://github.com/ /dotfiles) — trimmed and adapted for a comfortable Mac-first / Linux-compatible workflow.
