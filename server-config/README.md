# Server shell config

Lightweight, SSH-friendly shell for **Debian/Ubuntu** and **Arch** servers.

No oh-my-zsh, no GUI — fast prompt via [Starship](https://starship.rs), plus tmux and everyday CLI tools.

## Quick install

From this repo on the server:

```bash
chmod +x scripts/setup-server-shell.sh
./scripts/setup-server-shell.sh
# or non-interactive:
./scripts/setup-server-shell.sh --yes
```

## What you get

| Piece | Role |
|-------|------|
| `zsh` + Starship | Graceful prompt (user@host, path, git, duration) |
| `tmux` | Sessions that survive SSH drops (prefix `Ctrl-a`) |
| [Lazydocker](https://lazydocker.com/) | Terminal UI for containers, images, compose, logs |
| `btop` | Modern TUI system monitor (CPU / mem / disks / net) |
| [Netdata](https://www.netdata.cloud/) | Real-time metrics dashboard (`:19999`) |
| `fzf` `rg` `fd` `bat` `eza` | Fast search / browse |
| `htop` `ncdu` `jq` | Ops essentials |
| `aliasrc` | Server aliases (`bt`, `ld`, `s`, `ports`, `myip`, …) |

## Lazydocker

Installed automatically by `setup-server-shell.sh`:

- **Arch**: via `pacman` when the package exists, otherwise official binary script
- **Debian/Ubuntu**: official install script → `~/.local/bin`

```bash
lazydocker   # or: ld
```

Requires a running Docker daemon. Add your user to the `docker` group if stats are missing.

## btop

Installed via apt/pacman with the core package list.

```bash
btop   # or: bt
```

## Netdata

- **Arch**: `pacman` package `netdata` (enabled via systemd)
- **Debian/Ubuntu**: official [kickstart](https://learn.netdata.cloud/installing/one-line-installer-for-linux/) (non-interactive)

```bash
# Dashboard (open firewall/security group for 19999 if remote)
http://SERVER_IP:19999

systemctl status netdata
```

## Layout

```
server-config/
├── env                 # XDG + PATH
├── aliasrc             # Server aliases
├── starship.toml       # Prompt theme
├── zsh/                # .zshrc / .zprofile
├── tmux/tmux.conf
├── home/               # ~/.zshenv · ~/.zprofile
└── packages/
    ├── debian.txt
    └── arch.txt
```

## After install

```bash
exec zsh -l
tmux
btop         # system monitor
lazydocker   # Docker TUI
# Netdata UI: http://SERVER_IP:19999
```

Machine-specific overrides: `~/.config/zsh/local.zsh`
