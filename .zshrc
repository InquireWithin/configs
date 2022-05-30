HISTFILE=~/.histfile
HISTSIZE=25000
SAVEHIST=5000
zstyle :compinstall filename '/home/self/.zshrc'
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
#cursor changes depending on vi mode
function zle-keymap-select {
    if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then echo -ne '\e[1 q'
    elif [[ ${KEYMAP} == main ]] || [[ ${KEYMAP} == viins ]] || [[ ${KEYMAP} == '' ]] || [[ $1 = 'line' ]]; then echo -ne '\e[5 q'
    fi
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins
    echo -ne "\e[5 q"
}
zle -N zle-line-init() {
# block cursor defaults
echo -ne '\e[1 q'
preexec() { echo -ne '\e[1 q' ;}

#vim keys in the tab menu
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M '^?' backward-delete-char

#edit line in vim w/ ctrl + e
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line

