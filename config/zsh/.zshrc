# Zsh interactive config — portable Mac / Linux
# Prompt: starship (if installed) → geek theme → oh-my-zsh theme

export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export LANG="${LANG:-en_US.UTF-8}"
export ZSH="${ZSH:-$HOME/.config/oh-my-zsh}"
export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$HOME/.config/starship.toml}"

CASE_SENSITIVE="false"
HYPHEN_INSENSITIVE="false"
# Only used when oh-my-zsh loads AND starship/geek prompt are unavailable
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
  docker
  docker-compose
  fzf
  zsh-syntax-highlighting  # must be last
)

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

# ── oh-my-zsh (only if healthy) ─────────────────────────────────────
_OMZ_OK=0
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
  [[ ! -f "$ZSH/themes/${ZSH_THEME}.zsh-theme" && ! -f "$ZSH/custom/themes/${ZSH_THEME}.zsh-theme" ]] \
    && ZSH_THEME="robbyrussell"
  # Disable OMZ theme when we drive the prompt ourselves
  if command -v starship >/dev/null 2>&1 || [[ -f "${ZDOTDIR:-$HOME/.config/zsh}/prompt-geek.zsh" ]]; then
    ZSH_THEME=""
  fi
  source "$ZSH/oh-my-zsh.sh"
  _OMZ_OK=1
else
  # Manual plugin load when OMZ is broken / missing
  _plug="$HOME/.config/oh-my-zsh/custom/plugins"
  [[ -f "$_plug/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] \
    && source "$_plug/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [[ -f "$_plug/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] \
    && source "$_plug/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  [[ -d "$_plug/zsh-completions/src" ]] \
    && fpath=("$_plug/zsh-completions/src" $fpath)
  unset _plug
fi

# fzf — Homebrew/new builds expose `fzf --zsh`; Ubuntu apt uses examples/
if command -v fzf >/dev/null 2>&1; then
  if fzf --help 2>&1 | grep -q -- '--zsh'; then
    source <(fzf --zsh)
  else
    for _fzf_base in \
      /usr/share/doc/fzf/examples \
      /usr/share/fzf \
      /usr/share/fzf/shell \
      /opt/homebrew/opt/fzf/shell \
      /usr/local/opt/fzf/shell
    do
      [[ -f "$_fzf_base/key-bindings.zsh" ]] && source "$_fzf_base/key-bindings.zsh"
      [[ -f "$_fzf_base/completion.zsh" ]] && source "$_fzf_base/completion.zsh"
    done
    unset _fzf_base
  fi
fi

# zoxide — smarter cd (z / zi)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# fnm — Node version manager (auto-switch on cd via .node-version / .nvmrc)
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell zsh)"
elif [[ -x "${XDG_DATA_HOME:-$HOME/.local/share}/fnm/fnm" ]]; then
  eval "$("${XDG_DATA_HOME:-$HOME/.local/share}/fnm/fnm" env --use-on-cd --shell zsh)"
fi

autoload -Uz compinit
compinit -i -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"

# history-substring-search bindings (after omz)
if [[ -f "$ZSH/plugins/history-substring-search/history-substring-search.zsh" ]]; then
  [[ $_OMZ_OK -eq 0 ]] && source "$ZSH/plugins/history-substring-search/history-substring-search.zsh"
fi
bindkey '^[[A' history-substring-search-up 2>/dev/null || true
bindkey '^[[B' history-substring-search-down 2>/dev/null || true
bindkey -M vicmd '^e' edit-command-line 2>/dev/null || true

# Aliases
unalias l 2>/dev/null || true
[[ -f "${XDG_CONFIG_HOME}/aliasrc" ]] && . "${XDG_CONFIG_HOME}/aliasrc"

# ── Prompt (starship wins; else geek; else leave OMZ theme) ─────────
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
elif [[ -f "${ZDOTDIR:-$HOME/.config/zsh}/prompt-geek.zsh" ]]; then
  source "${ZDOTDIR:-$HOME/.config/zsh}/prompt-geek.zsh"
fi

# Local overrides (machine-specific)
[[ -f "${XDG_CONFIG_HOME}/zsh/local.zsh" ]] && . "${XDG_CONFIG_HOME}/zsh/local.zsh"

unset _OMZ_OK

# bun completions
[ -s "/home/dev/.local/share/bun/_bun" ] && source "/home/dev/.local/share/bun/_bun"
