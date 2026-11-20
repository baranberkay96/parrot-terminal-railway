# shellcheck shell=bash
# Parrot Web Terminal shell defaults (/etc/parrot-terminal/bashrc).
# ~/.bashrc sources this at its end. The file comes with the image and is
# replaced on updates. Put your own changes in ~/.bashrc or ~/.bash_aliases,
# which are on the volume.

case $- in
  *i*) ;;
  *) return ;;
esac

# PATH: per-user installs on the volume come first.
for _dt_dir in "$HOME/bin" "$HOME/.local/bin" "$HOME/go/bin"; do
  case ":$PATH:" in
    *":$_dt_dir:"*) ;;
    *) PATH="$_dt_dir:$PATH" ;;
  esac
done
unset _dt_dir
export PATH

export EDITOR="${EDITOR:-nano}"
export VISUAL="${VISUAL:-$EDITOR}"
export PAGER="${PAGER:-less}"
export LESS="${LESS:--R}"

# History: large, timestamped, and appended after every command, so tmux
# windows share it and it survives restarts.
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth
HISTTIMEFORMAT='%F %T  '
shopt -s histappend checkwinsize cmdhist
case "${PROMPT_COMMAND:-}" in
  *"history -a"*) ;;
  *) PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac

alias ll='ls -alFh --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'

# Prompt in Parrot's two-line style: ┌─[user@host]─[dir] (git branch), then
# └──╼ $. Set PROMPT_HOST in ~/.bashrc to rename the host part. The container
# hostname is a random id on Railway.
_dt_git=''
if [[ -r /usr/lib/git-core/git-sh-prompt ]]; then
  # shellcheck source=/dev/null
  . /usr/lib/git-core/git-sh-prompt
  GIT_PS1_SHOWDIRTYSTATE=1
  GIT_PS1_SHOWUPSTREAM=auto
  _dt_git='$(__git_ps1 " (%s)")'
fi
if (( EUID == 0 )); then
  _dt_user='\[\e[0;31m\]┌─[\[\e[1;31m\]\u\[\e[1;33m\]@\[\e[1;96m\]'
else
  _dt_user='\[\e[0;31m\]┌─[\[\e[0;39m\]\u\[\e[1;33m\]@\[\e[1;96m\]'
fi
PS1="${_dt_user}${PROMPT_HOST:-railway}\[\e[0;31m\]]─[\[\e[0;32m\]\w\[\e[0;31m\]]\[\e[0;33m\]${_dt_git}\n\[\e[0;31m\]└──╼ \[\e[1;33m\]\\$\[\e[0m\] "
unset _dt_git _dt_user

# Welcome banner: once per tmux session (or once per plain login shell).
# `touch ~/.hushlogin` turns it off.
_dt_banner() {
  [[ -r /etc/parrot-terminal/motd ]] && cat /etc/parrot-terminal/motd
  # CPU, memory and disk are left out: inside a container fastfetch reports the
  # whole Railway host, not this service's plan limits.
  if command -v fastfetch > /dev/null 2>&1; then
    fastfetch --logo-type small \
      --structure Title:Separator:OS:Kernel:Shell 2> /dev/null || true
  fi
}
if [[ ! -e "$HOME/.hushlogin" ]] && shopt -q login_shell; then
  if [[ -n "${TMUX:-}" ]]; then
    if ! tmux show-environment DT_BANNER_SHOWN > /dev/null 2>&1; then
      tmux set-environment DT_BANNER_SHOWN 1 2> /dev/null
      _dt_banner
    fi
  else
    _dt_banner
  fi
fi
unset -f _dt_banner
