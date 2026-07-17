# Zsh interactive config — portable Mac / Linux
# Inspired by https://github.com/ /dotfiles

export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export LANG="${LANG:-en_US.UTF-8}"
export ZSH="${ZSH:-$HOME/.config/oh-my-zsh}"

CASE_SENSITIVE="false"
HYPHEN_INSENSITIVE="false"
ZSH_THEME="${ZSH_THEME:-robbyrussell}"
DISABLE_AUTO_UPDATE="true"
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="yyyy-mm-dd"
HISTSIZE=100000
SAVEHIST=100000

VI_MODE_SET_CURSOR=true
VI_MODE_CURSOR_INSERT=2
VI_MODE_CURSOR_NORMAL=6

plugins=(
  git
  sudo
  colored-man-pages
  zsh-autosuggestions
  zsh-completions
  history-substring-search
  vi-mode
)

# Fall back to a built-in theme if custom theme is missing
[[ ! -f "$ZSH/themes/${ZSH_THEME}.zsh-theme" && ! -f "$ZSH/custom/themes/${ZSH_THEME}.zsh-theme" ]] \
  && ZSH_THEME="robbyrussell"

## Options
setopt nocheckjobs
setopt numericglobsort
setopt appendhistory
setopt histignorealldups
setopt sharehistory
setopt hist_ignore_space
zstyle ':completion:*' menu yes select
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

WORDCHARS=${WORDCHARS//\/[&.;]/}

## Keybindings
bindkey -v
bindkey '^H' backward-kill-word
bindkey '^z' undo
bindkey '^b' backward-word
bindkey '^w' forward-word
bindkey '^ ' autosuggest-accept

fpath=("$HOME/.local/share/zsh/completions" $fpath)

[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# fzf
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh) 2>/dev/null || true
fi

autoload -Uz compinit
compinit -i -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"

# history-substring-search bindings (after omz)
bindkey '^[[A' history-substring-search-up 2>/dev/null || true
bindkey '^[[B' history-substring-search-down 2>/dev/null || true
bindkey -M vicmd '^e' edit-command-line 2>/dev/null || true

# Aliases
unalias l 2>/dev/null || true
[[ -f "${XDG_CONFIG_HOME}/aliasrc" ]] && . "${XDG_CONFIG_HOME}/aliasrc"

# Local overrides (machine-specific)
[[ -f "${XDG_CONFIG_HOME}/zsh/local.zsh" ]] && . "${XDG_CONFIG_HOME}/zsh/local.zsh"
