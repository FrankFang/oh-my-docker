[ `alias | grep "^ls=" | wc -l` != 0 ] && unalias ls
alias gst='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gl='git pull'
alias gp='git push'
alias ls='exa'
alias ll='ls -lh'
alias la='ls -alh'
[ -f ~/.bash_aliases.local ] && { source ~/.bash_aliases.local }
[ -f ~/.rvm/scripts/rvm ] && { source ~/.rvm/scripts/rvm }