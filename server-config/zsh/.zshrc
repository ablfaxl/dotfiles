#!/bin/zsh
# Graceful server zsh — no oh-my-zsh (fast on SSH)

. "${XDG_CONFIG_HOME:-$HOME/.config}/env"

# History
HISTFILE="${XDG_DATA_HOME:-$HOME/.local/share}/zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt appendhistory
setopt sharehistory
setopt histignorealldups
setopt hist_ignore_space
setopt hist_reduce_blanks

# Options
setopt autocd
setopt correct
setopt interactivecomments
setopt nocheckjobs
setopt numericglobsort

# Completion
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
autoload -Uz compinit
compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Keybindings — emacs-friendly for servers (vi optional via local.zsh)
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# Colors for ls if no eza
[[ -z "${LS_COLORS:-}" ]] && command -v dircolors >/dev/null 2>&1 && eval "$(dircolors -b)"

# fzf
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh) 2>/dev/null || true
fi

# Aliases
[[ -f "${XDG_CONFIG_HOME}/aliasrc" ]] && . "${XDG_CONFIG_HOME}/aliasrc"

# Starship prompt (graceful, informative, fast)
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
else
  # Fallback prompt if starship missing
  PROMPT='%F{cyan}%n@%m%f %F{blue}%1~%f %# '
fi

# Optional machine-local overrides
[[ -f "${XDG_CONFIG_HOME}/zsh/local.zsh" ]] && . "${XDG_CONFIG_HOME}/zsh/local.zsh"
