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
| `fzf` `rg` `fd` `bat` `eza` | Fast search / browse |
| `htop` `ncdu` `jq` | Ops essentials |
| `aliasrc` | Server aliases (`s`, `ports`, `ld`, `myip`, git shortcuts) |

## Lazydocker

Installed automatically by `setup-server-shell.sh`:

- **Arch**: via `pacman` when the package exists, otherwise official binary script
- **Debian/Ubuntu**: official install script → `~/.local/bin`

```bash
# Manual install / update (Linux)
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
# Custom install dir:
# DIR=/usr/local/bin bash <(curl -fsSL ...)

lazydocker   # or: ld
```

Requires a running Docker daemon. Add your user to the `docker` group if stats are missing.

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
lazydocker   # Docker TUI
```

Machine-specific overrides: `~/.config/zsh/local.zsh`
