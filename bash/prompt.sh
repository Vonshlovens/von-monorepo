# Custom prompt: user  cwd  git-branch*  ❯  (uses theme palette)
# Source this from ~/.bashrc
__prompt_git() {
  local b
  b=$(git symbolic-ref --short HEAD 2>/dev/null) || return
  local dirty=""
  [[ -n $(git status --porcelain 2>/dev/null) ]] && dirty="*"
  printf '\001\e[01;35m\002  %s%s\001\e[0m\002' "$b" "$dirty"
}
PS1='\[\e[01;32m\]\u\[\e[0m\] \[\e[01;34m\]\w\[\e[0m\]$(__prompt_git)\n\[\e[01;36m\]❯\[\e[0m\] '
