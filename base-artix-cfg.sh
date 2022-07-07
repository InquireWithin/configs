#This file documents changes I made that I recall
#dates are in dd/mm/yy, time is 24h

#Init service is openrc, first installed this iteration of the os in the first week of may 2022
#Desktop env: xfce4 (startxfce4 to launch it manually)
#THIS WAS WRITTEN BEFORE I KNEW THERE WAS AN AUTOINSTALLER FOR XFCE ON THE ARTIX WIKI
#!/bin/bash


#provides verbosity when errors inevitably occur
set -x
#don't run as root
[ "$(id -u)" = 0 ] && echo "This script should not be ran as root, as most of it will break. Consider creating or logging into a user account that can use sudo before running." && exit 1

#This is just to allow for full automation of the script in advance by placing the user's password here
PASSWORD=""
CARDTYPE="" #graphics card manufacturer
#graphics driver config-dependent 
[[ $(lspci | grep -ci vga) > 1 ]] && echo "ERROR: Script currently not supported for > 1 graphics card"
#for some ungodly reason there are exactly 7 spaces prior to the string, piping into sed w/ that expression will remove preceding whitespace
[[ $(sudo lshw -C display | grep vendor | sed 's/^ *//g') == "vendor: NVIDIA Corporation" ]] && CARDTYPE="NVIDIA"
#manually configure these variables:
GITUSER="" #username for git config
GITMAIL="" #email for git config
DEFAULTBRANCHNAME="master"
USEXFCE4="TRUE" #set up for xfce4 desktop environment
USEZSH="TRUE" #flags whether zsh should be installed and used over bash as a default shell
PKGFILE="" #filepath to manually download packages from

#this script currently only supports intel cpu's (in terms of graphics). it can be ran w/o an nvidia gpu but no graphical config will be made. It can be ran w/o setting usexfce4 TRUE, but no DE config will be made.
#uses pulseaudio by default
#the AUR helper is yay by default
#an internet connection is assumed and required. I might add something later on that will help do this if none is found
#Finally, it's also highly advised to be on a user account you've already created. Maybe I'll add this in the script at some point. This user should have sudo privileges.

#If the password field is not an empty string, feed it into sudo
export HISTIGNORE='*sudo -S*' #done so that pw cant be reaped from shell history
[[ ! -n ${PASSWORD+x} ]] && alias sudo="echo "$PASSWORD" | sudo -Sk" #might break commands that require extra input after exec'd (pacman, for example)

#Will install whatever packages are specified in the filepath in $PKGFILE assuming the variable isnt set to an empty string (null)
[[ ! -n ${PKGFILE+x} ]] && sudo pacman -S --noconfirm - < $PKGFILE 
#recommended but optional packages
#sudo pacman -Syu --noconfirm wget gedit hwinfo htop unzip traceroute neomutt neovim shutter
#essentials
sudo pacman -Syu --noconfirm curl man vim artix-archlinux-support git pulseaudio pulseaudio-alsa lib32-libpulse lib32-alsa-plugins zathura mpv pavucontrol gnu-free-fonts ttf-liberation

#yay installation b/c eventually I'll need an AUR exclusive package. this wont work in root user
cd /opt && sudo git clone https://aur.archlinux.org/yay-git.git && sudo chmod 777 -r yay-git && cd yay-git && makepkg -si && cd $HOME
#yay -S --noconfirm ttf-ms-win11 #if you ever plan to use steam, uncomment

if [ $USEZSH=="TRUE" ] then
    sudo pacman -S --noconfirm zsh
    chsh -s /bin/zsh
    yay -S --noconfirm zsh-syntax-highlighting
    curl https://github.com/InquireWithin/configs/tree/main/dotfiles/.zshrc >> ~/.zshrc
    source ~/.zshrc
fi

[[ $USEXFCE4=="TRUE" ]] && sudo pacman --noconfirm -S xfce4 xfce4-goodies

#default editor as vim, persistently
[[ -f /usr/bin/nvim ]] && sudo echo "EDITOR=/usr/bin/nvim" >> /etc/environment || sudo echo "EDITOR=/usr/bin/vim" >> /etc/environment
sudo chmod 777 /etc/pacman.conf
#Integrate compatibility for extra, mutilib, and community repos here 
sudo echo "[extra]\nInclude = /etc/pacman.d/mirrorlist-arch\n\n[community]\nInclude=/etc/pacman.d/mirrorlist-arch\n\n[multilib]\nInclude=/etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
pacman-key --populate archlinux

#install nvidia drivers for NV110/GMXXX series or higher (checked via nvidia driver download page)
# proprietary drivers, using for xorg (dependency of xfce)
# default linux kernel
if [ $CARDTYPE == "NVIDIA" ] then
    #creating a "just in case" file as the wiki suggested making a 20-intel.conf over an xorg.conf (likely b/c pacman has an affinity for breaking an xorg.conf)
    sudo pacman -S --noconfirm xf86-video-intel nvidia nvidia-settings
    [[ $USEXFCE4=="TRUE" ]] && chmod 777 /etc/X11/xorg.conf.d/ && sudo touch "/etc/X11/xorg.conf.d/20-intel.conf"
    sudo chmod 777 /etc/X11/xorg.conf.d/20-intel.conf && echo "Section \"Device\"\n\tIdentifier \"Intel Graphics\"\n\tDriver \"Intel\"\nEndSection" >> /etc/X11/xorg.conf.d/20-intel.conf
    # ^ Leaving this as is due to the fact it needs to be read and accessed by the user. Don't know if it needs to write but not worth the gamble of breaking the whole config.

    #sudo pacman -S lib32-nvidia-utils #32-bit app support (multilib req, should already be configured)
    sudo mkdir /etc/pacman.d/hooks
    sudo chown $USER:$USER /etc/pacman.d/hooks #chmod 777 worked for me for all instances of this the first time
    touch /etc/pacman.d/hooks/nvidia.hook && echo "[Trigger]\nOperation=Install\nOperation=Remove\nType=Package\nTarget=nvidia\nTarget=linux\n[Action]\nDepends=mkinitcpio\nWhen=PostTransaction\nNeedsTargets\nExec=/bin/sh -c 'while read -r trg; do case \$trg in linux) exit 0; esac ; done; /usr/bin/mkinitcpio -P'" > /etc/pacman.d/hooks/nvidia.hook 
    #above logic avoids no upgrade of initramfs after upgrading nvidia drivers, also prevents mkinitcpio from running more than once
    sudo chown $USER:$USER -r /etc/pacman.d/hooks 
    [[ $USEXFCE4=="TRUE" ]] && sudo chown $USER:$USER -r /etc/X11 #will work for all WM's using X but I may as well not do this unless one is already being set up, like xfce.
    sudo nvidia-xconfig 
fi

#two monitor support
#this is VERY SPECIFIC, this command syntax I use here assumes you have 2 monitors: one is HDMI connected via HDMI-1 and it is on the right (user facing) of
#a monitor connected by DVI-I-1. For my setup, the resolution defaults to 1920x1080, though I believe --mode can configure it (See "Multihead" on Arch Wiki)
#xrandr --output DVI-I-1 --auto --output HDMI-0 --auto --right-of DVI-I-1
#change primary monitor via display settings GUI of xfce4 (click on applications on the left of the top panel and find "Settings Manager" or "Display")

[[ $USEXFCE4 == "TRUE" ]] && echo "#!/bin/bash\n[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && startxfce4" >> ~/.xinitrc
[[ -f $HOME/.asoundrc ]] && rm $HOME/.asoundrc # its not supposed to exist
cd $HOME
sudo chmod u+r /etc/pulse/daemon.conf #just in case this permission isn't present
#copy settings from the system's configuration into a user-specific config (changes made in the file inside home (~) will only affect the current user and are not system wide
cp /etc/pulse/daemon.conf ~/.pulse/daemon.conf
sudo echo flat-volumes=no >> ~/.pulse/daemon.conf

#I hate tabs b/c it makes python an impossibility
tabs 4 #tabs should now be set to 4 spaces

#git config
git config --global user.name $GITUSER
git config --global user.email $GITMAIL
git config --global core.editor $EDITOR
#personal preference, I still have repos that use this, they screwed people over when they changed the default.
[[ ! -n $DEFAULTBRANCHNAME ]] && git config --global init.defaultBranch $DEFAULTBRANCHNAME

#vimrc
curl https://github.com/InquireWithin/configs/tree/main/dotfiles/.vimrc > ~/.vimrc
source ~/.vimrc

#bashrc
curl https://github.com/InquireWithin/configs/tree/main/dotfiles/.bashrc > ~/.bashrc
source ~/.bashrc

#hosts file domain blocking (decreases the urgency of acquiring an ad-blocker and helps for browsers with limited support for ad-blocking extensions or integration)
sudo chmod 777 /etc/hosts && curl https://github.com/InquireWithin/resources/tree/main/LF/LF_extended_telemetry_list.txt >> /etc/hosts && sudo chmod 644 /etc/hosts

#remove any orphaned packages
sudo pacman --noconfirm -R $(pacman -Qtdq)

#launch the DE
exec startx









