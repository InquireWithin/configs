#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return


# PS1='[\u@\h \W]\$ '

#bash specific
    #source
source /usr/share/git/completion/git-completion.bash
    #bash-specific aliases
alias ls='ls --color=auto'

#aliases
alias cp='cp -iv'
alias wc='wc -w'
alias pm='sudo pacman'
#DE-specific aliases
alias sx4='startxfce4'
#software-specific aliases
alias sigd='signal-desktop'

#time-savers
shopt -s autocd

#funcs for aliases

#'mvd' command will now automatically create a directory when moving file(s) to a target dir that does not exist
function mvd()
{ #include a slash at the end of a directory
    dir="${!#}"
    tmp="${!#}";tmp="${tmp: -1}"
    [ "$tmp" != "/" ] && dir="$(dirname "${!#}")"
    [ -a "$dir" ] ||
    mkdir -p "$dir" &&
    mv "$@"
}

#'cpd' command will now automatically copy files to the name and path of the last argument and create that dir if it doesn't exist, works like mvd
function cpd() 
{
    dir="${!#}"
    tmp="${!#}";tmp="${tmp: -1}"
    [ "$tmp" != "/" ] && dir="$(dirname "${!#}")"
    [ -d "$dir" ] ||
    mkdir -p "$dir" &&
    cp "$@"
}
