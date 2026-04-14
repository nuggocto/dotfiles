[[ $- != *i* ]] && return

HISTFILE="$HOME/.zsh_history"
HISTSIZE=32768
SAVEHIST=32768

setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY
setopt NO_HIST_BEEP
setopt SHARE_HISTORY

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

mkdir -p "$HOME/.cache/zsh"

autoload -Uz compinit
compinit -d "$HOME/.cache/zsh/zcompdump-$ZSH_VERSION"
autoload -Uz colors && colors
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey -v
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey -M vicmd 'k' up-line-or-beginning-search
bindkey -M vicmd 'j' down-line-or-beginning-search
bindkey -M viins 'jj' vi-cmd-mode

if [[ -z "$LS_COLORS" ]] && command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b)"
fi

zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if [[ -o zle ]] && command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v try >/dev/null 2>&1; then
  eval "$(SHELL=/bin/zsh command try init "$HOME/Work/tries")"
fi

[[ -f /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh
[[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh

if command -v eza >/dev/null 2>&1; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias c='opencode'
alias chrome='google-chrome-stable --remote-debugging-port=9222'
alias google-chrome='google-chrome-stable --remote-debugging-port=9222'
alias d='docker'
alias g='git'
alias ga='git add'
alias gb='git branch'
alias gc='git commit'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'
alias gd='git diff'
alias gl='git log --oneline --decorate --graph -20'
alias gp='git push'
alias gs='git status -sb'
alias oc='omarchy-theme-current'
alias od='omarchy-debug --no-sudo --print'
alias or='omarchy-restart-terminal'
alias r='rails'
alias t='tmux attach || tmux new -s Work'

n() {
  if (( $# == 0 )); then
    command nvim .
  else
    command nvim "$@"
  fi
}

open() {
  xdg-open "$@" >/dev/null 2>&1 &
}

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
