HISTFILE=~/.histfile
HISTSIZE=25000
SAVEHIST=5000
HISTIGNORE='*sudo -S*'

#aliases
alias icat='icecat'
alias cp='cp -iv'
alias wc='wc -w'
alias pm='sudo pacman'
alias pms='sudo pacman -S'
alias pmsn='sudo pacman -S --noconfirm'
alias pmsu='sudo pacman -Syu'
alias sl='ls'
alias vzsh='vim ~/.zshrc'
alias vbash='vim ~/.bashrc'

#DE-specific aliases
alias sx4='startxfce4'
#software-specific aliases
alias sigd='signal-desktop'


#funcs for aliases

#'mvd' command will now automatically create a directory when moving file(s) to a target dir that does not exist
function mvd()
{ #include a slash at the end of a directory
    dir="$_"
    tmp="$_";tmp="${tmp: -1}"
    [ -d "$dir" ] || mkdir -p "$dir"
    [ -d "$dir" ] && echo "created directory $dir"
    mv "$@"
}

#'cpd' command will now automatically copy files to the name and path of the last argument and create that dir if it doesn't exist, works like mvd
function cpd() 
{
    dir="$_"
    tmp="$_";tmp="${tmp: -1}"
    [ -d "$dir" ] || mkdir -p "$dir"
    [ -d "$dir" ] && echo "created directory $dir"
    cp "$@"
}

#tab completion
zstyle :compinstall filename "$HOME/.zshrc"
autoload -Uz compinit # load completioninit module
zstyle ':completion:*' menu select # menu style tab completion
zmodload zsh/complist
compinit
_comp_options+=(globdots) # view hidden files enabled
autoload -U colors && colors
PS1="%B%{$fg[green]%}[%{$fg[blue]%}%n%{$fg[magenta]%}@%{$fg[red]%}%M %{$fg[magenta]%}%~%{$fg[green]%}]%{$reset_color%}$%b "
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

#implementation of vi mode in zsh
bindkey -v
export KEYTIMEOUT=1
#CHANGE CURSOR BASED ON VI MODE
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
elif [[ ${KEYMAP} == main ]] ||
      [[ ${KEYMAP} == viins ]] ||
      [[ ${KEYMAP} == '' ]] ||
      [[ $1 = 'line' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[1 q'
preexec() { echo -ne '\e[1 q' ;}

#vim keys in autocomplete menu
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char



