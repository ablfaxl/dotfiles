# Zsh interactive config -- portable macOS / Linux
# Minimal dependencies, maximum productivity.

export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export LANG="${LANG:-en_US.UTF-8}"
export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$HOME/.config/starship.toml}"

HISTSIZE=100000
SAVEHIST=100000

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
bindkey '^H' backward-kill-word
bindkey '^b' backward-word

fpath=("$HOME/.local/share/zsh/completions" $fpath)

# Lightweight plugins from existing local Oh My Zsh plugin dirs.
for _plug_base in "$HOME/.config/oh-my-zsh/custom/plugins" "$HOME/.oh-my-zsh/custom/plugins"; do
  [[ -f "$_plug_base/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] \
    && source "$_plug_base/zsh-autosuggestions/zsh-autosuggestions.zsh" && break
done
for _plug_base in "$HOME/.config/oh-my-zsh/custom/plugins" "$HOME/.oh-my-zsh/custom/plugins"; do
  [[ -d "$_plug_base/zsh-completions/src" ]] \
    && fpath=("$_plug_base/zsh-completions/src" $fpath) && break
done
unset _plug_base

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

# mise — project runtime manager
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

autoload -Uz compinit
compinit -i -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"

# Aliases
unalias l 2>/dev/null || true
[[ -f "${XDG_CONFIG_HOME}/aliasrc" ]] && . "${XDG_CONFIG_HOME}/aliasrc"

# ── Prompt (starship wins; else geek; else leave OMZ theme) ─────────
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
elif [[ -f "${ZDOTDIR:-$HOME/.config/zsh}/prompt-geek.zsh" ]]; then
  source "${ZDOTDIR:-$HOME/.config/zsh}/prompt-geek.zsh"
fi

# zsh-syntax-highlighting must be loaded after widgets are defined.
for _plug_base in "$HOME/.config/oh-my-zsh/custom/plugins" "$HOME/.oh-my-zsh/custom/plugins"; do
  [[ -f "$_plug_base/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] \
    && source "$_plug_base/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" && break
done
unset _plug_base

# Local overrides (machine-specific)
[[ -f "${XDG_CONFIG_HOME}/zsh/local.zsh" ]] && . "${XDG_CONFIG_HOME}/zsh/local.zsh"

# bun completions
[[ -s "${BUN_INSTALL:-$HOME/.bun}/_bun" ]] && source "${BUN_INSTALL:-$HOME/.bun}/_bun"
