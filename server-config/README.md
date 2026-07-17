# Server shell config

Lightweight, SSH-friendly shell for **Debian/Ubuntu** and **Arch** servers.

No oh-my-zsh, no GUI — fast prompt via [Starship](https://starship.rs), plus tmux and everyday CLI tools.

## Quick install

From this repo on the server:

```bash
chmod +x scripts/setup-server-shell.sh
./scripts/setup-server-shell.sh --yes

# Iran networks (apt blocked / Docker repo 403):
./scripts/setup-server-shell.sh --yes --iran

# Pick a specific mirror:
./scripts/setup-server-shell.sh --yes --mirror iut
./scripts/setup-server-shell.sh --yes --mirror iranserver
./scripts/setup-server-shell.sh --yes --url https://ae.archive.ubuntu.com/ubuntu/
```

### Iran / Ubuntu mirrors

```bash
./server-config/mirrors/setup-iran-mirrors.sh --list
./server-config/mirrors/setup-iran-mirrors.sh --list-all   # 128 Ubuntu URLs
./server-config/mirrors/setup-iran-mirrors.sh --mirror sindad
./server-config/mirrors/setup-iran-mirrors.sh --auto       # probe until apt works
```

| ID | Provider | Host |
|----|----------|------|
| `arvan` (default) | ArvanCloud | `mirror.arvancloud.ir` |
| `iut` | Isfahan University of Technology | `mirror.iut.ac.ir` |
| `iust` | Iran University of Science and Technology | `mirror.iust.ac.ir` |
| `um` | Ferdowsi University of Mashhad | `mumirror.um.ac.ir` |
| `iranserver` | IranServer | `mirror.iranserver.com` |
| `sindad` | Sindad | `ir.ubuntu.sindad.cloud` |
| `faraso` / `pishgaman` / `ir-archive` | more IR options | see `--list` |

Full catalog: [`mirrors/ubuntu-mirrors.txt`](./mirrors/ubuntu-mirrors.txt)

Also disables broken `download.docker.com` apt sources that return **403 Forbidden**.

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
