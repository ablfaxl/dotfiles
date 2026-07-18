# Geek prompt — works with or without oh-my-zsh / starship
# cyan path · yellow git · magenta user · green/red ❯

autoload -Uz colors && colors
autoload -Uz vcs_info
setopt prompt_subst

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' stagedstr '%F{green}+%f'
zstyle ':vcs_info:*' unstagedstr '%F{red}*%f'
zstyle ':vcs_info:git:*' formats ' %F{yellow}git:(%b%c%u%F{yellow})%f'
zstyle ':vcs_info:git:*' actionformats ' %F{yellow}git:(%b|%a%c%u%F{yellow})%f'

# Capture exit status before anything else in precmd
_geek_precmd() {
  local ec=$?
  vcs_info
  if (( ec == 0 )); then
    _GEEK_MARK="%F{green}❯%f"
  else
    _GEEK_MARK="%F{red}❯%f"
  fi
}

# Avoid duplicate hooks on reload
typeset -ga precmd_functions
precmd_functions=(${precmd_functions:#_geek_precmd})
precmd_functions+=(_geek_precmd)

# Short path: keep ~ and last two segments
_geek_pwd() {
  local p="${PWD/#$HOME/~}"
  local parts=(${(s:/:)p})
  local n=${#parts}
  if (( n <= 3 )); then
    print -r -- "$p"
    return
  fi
  local out="" i
  for (( i=1; i<=n; i++ )); do
    if (( i == 1 || i >= n - 1 )); then
      out+="${parts[i]}"
    else
      [[ -n ${parts[i]} ]] && out+="${parts[i][1]}"
    fi
    (( i < n )) && out+="/"
  done
  print -r -- "$out"
}

PROMPT=$'%F{magenta}%n%f%F{cyan}@%m%f %F{blue}%B$(_geek_pwd)%b%f${vcs_info_msg_0_}\n${_GEEK_MARK} '
RPROMPT='%F{240}%*%f'
