# Troubleshooting

## ZSH Not Loading

Run:

```sh
zsh -n ~/.config/zsh/.zshrc
exec zsh
```

## PATH Problems

Run:

```sh
path
doctor
```

## Homebrew Issues

Run:

```sh
brew doctor
brew update
```

## Node / pnpm Issues

Run:

```sh
node -v
pnpm -v
corepack enable
```

## tmux Issues

Run:

```sh
tmux source-file ~/.config/tmux/tmux.conf
```

## Git SSH Issues

Run:

```sh
ssh -T git@github.com
gh auth status
```

