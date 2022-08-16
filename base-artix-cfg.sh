#!/usr/bin/env bash
#provides verbosity when errors inevitably occur
set -x

#USER-SET VARIABLES. SET THESE MANUALLY
PASSWORD="" #password for the user running the script.
#manually configure these variables:
USEXFCE4="TRUE" #set up for xfce4 desktop environment.
USEZSH="TRUE" #flags whether zsh should be installed and used over bash as a default shell.
PKGFILE="" #filepath of a text file for a list of packages for pacman to install
USEARCHREPOS="FALSE" #use arch repos such as multilib, extra, and community, requires repo lib32 to already be enabled, and requires mirrorlist-arch, must also be below all artix repos in /etc/pacman.conf. Might also need artix-archlinux-support

#OPTIONAL
GITUSER="" #username for git config.
GITMAIL="" #email for git config.
DEFAULTBRANCHNAME="master"

#NON-MANUALLY SET VARIABLES
CARDTYPE="" #graphics card manufacturer.

#This script MUST be ran on a user account with sudo privileges, see /etc/sudoers and edit it in a root acc with the command 'visudo' or edit it w/ a vi-based editor (vi, vim, nvim)
#this script currently only supports intel cpu's (in terms of graphics). it can be ran w/o an nvidia gpu but no graphical config will be made. It can be ran w/o setting usexfce4 TRUE, but no DE config will be made.
#Uses PulseAudio by default. Pipewire could be good but PulseAudio just works
#the AUR helper is yay by default.
#an internet connection is assumed and required. I might add something later on that will help do this if none is found.
#Finally, it's also highly advised to be on a user account you've already created. Maybe I'll add this in the script at some point. This user should have sudo privileges.
#I'm not a fan of wayland (pretty obvious why considering this script is made for nvidia cards), so I assume only X11 is used.

#don't run as root
[ "$(id -u)" -eq 0 ] && echo "This script should not be ran as root, as most of it will break. Consider creating or logging into a user account that can use sudo before running." && exit 1

#for some ungodly reason there are exactly 7 spaces prior to the string, piping into sed w/ that expression will remove preceding whitespace.
[[ $(sudo lshw -C display | grep vendor | sed 's/^ *//g') == "vendor: NVIDIA Corporation" ]] && CARDTYPE="NVIDIA"
#graphics driver config-dependent. Fix the pipe into grep, it's bloat.
[[ $(lspci | grep -ci vga) > 1 ]] && echo "ERROR: Script currently not supported for > 1 graphics card"
export HISTIGNORE='*sudo -S*' #done so that pw cant be reaped from shell history.
#sudo -S would typically work fine, but 'k' is used to continuously refresh the sudo auth cache so the password is never seen in the shell or executed as a command.
#sudo -Sk allows greater consistency as well, working the same regardless of the user's sudo timeout (iirc it's 5 min by default, some people change it.)
#If the password field is not an empty string, feed it into sudo.
[[ ! -n ${PASSWORD+x} ]] && alias sudo="echo "$PASSWORD" | sudo -Sk" #might break commands that require extra input after exec'd (pacman, for example)

#Will install whatever packages are specified in the filepath in $PKGFILE assuming the variable isnt set to an empty string (null)
[[ ! -n ${PKGFILE+x} ]] && sudo pacman -S --noconfirm - < $PKGFILE 
#recommended but optional packages
#sudo pacman -Syu --noconfirm wget gedit hwinfo htop unzip traceroute neomutt neovim shutter btrfs-progs dosfstools dos2unix transmission-cli groff scim
#essentials
sudo pacman -Syu --noconfirm gcc curl man go make fakeroot vim git pulseaudio pulseaudio-alsa lib32-libpulse lib32-alsa-plugins zathura mpv pavucontrol gnu-free-fonts ttf-liberation

#yay installation b/c eventually I'll need an AUR exclusive package. this wont work in root user
cd /opt && sudo git clone https://aur.archlinux.org/yay-git.git && sudo chmod 777 yay-git -R && cd yay-git && makepkg -si && cd $HOME


#Ensuring XDG directory specifcation defaults are met. Mostly redundant, however.
declare -A xdgarr=(["XDG_DATA_HOME"]='$HOME/.local/share' ["XDG_CONFIG_HOME"]='$HOME/.config' ["XDG_CACHE_HOME"]='$HOME/.cache' ["XDG_DATA_DIRS"]='usr/local/share/:/usr/share/' ["XDG_CONFIG_DIRS"]='/etc/xdg')
for i in "${!xdgarr[@]}"
    do
        sudo echo $i="${xdgarr[$i]}" >> /etc/profile
    done

#zsh
if [ $USEZSH = "TRUE" ] then
    sudo pacman -S --noconfirm zsh
    chsh -s /bin/zsh
    yay -S --noconfirm zsh-syntax-highlighting &
    curl https://github.com/InquireWithin/configs/tree/main/dotfiles/.zshrc >> ~/.zshrc
    source ~/.zshrc
fi
[[ $USEXFCE4 = "TRUE" ]] && sudo pacman --noconfirm -S xfce4 xfce4-goodies
#default editor as vim, persistently, except if nvim exists which would be used instead.
[[ -f /usr/bin/nvim ]] && sudo echo "EDITOR=/usr/bin/nvim" >> /etc/profile || sudo echo "EDITOR=/usr/bin/vim" >> /etc/profile
sudo chmod 777 /etc/pacman.conf
printf "[lib32]\nInclude = /etc/pacman.d/mirrorlist\n[universe]\nServer = https://universe.artixlinux.org/\$arch\nServer = https://mirror1.artixlinux.org/universe/\$arch\nServer = https://mirror.pascalpuffke.de/artix-universe/\$arch\nServer = https://artixlinux.qontinuum.space/artixlinux/universe/os/\$arch\nServer = https://mirror1.cl.netactuate.com/artix/universe/\$arch\nServer = https://ftp.crifo.org/artix-universe/\0" >> /etc/pacman.conf
#Integrate compatibility for extra, mutilib, and community repos here, if enabled
sudo pacman -Sy --noconfirm archlinux-keyring artix-archlinux-support #artix-archlinux-support comes from universe now, which should be enabled
sudo pacman-key --populate archlinux #only thing that was done the first go around was this line
#NOTE: do not manually create a mirrorlist-arch
[[ $USEARCHREPOS = 'TRUE' ]] && printf "[extra]\nInclude = /etc/pacman.d/mirrorlist-arch\n\n[community]\nInclude=/etc/pacman.d/mirrorlist-arch\n\n[multilib]\nInclude=/etc/pacman.d/mirrorlist-arch\0" >> /etc/pacman.conf
sudo pacman -Sy
sudo chmod 644 /etc/pacman.conf

#install nvidia drivers for NV110/GMXXX series or higher (checked via nvidia driver download page)
# proprietary drivers, using for xorg. I chose proprietary by default b/c the speed diff b/t this and nouveau is too significant.
# assuming usage of default kernel
if [ $CARDTYPE = "NVIDIA" ] then
    #creating a "just in case" file as the wiki suggested making a 20-intel.conf over an xorg.conf (likely b/c pacman has an affinity for breaking an xorg.conf)
    sudo pacman -S --noconfirm xf86-video-intel nvidia nvidia-settings
    chmod 777 /etc/X11/xorg.conf.d/ && sudo touch "/etc/X11/xorg.conf.d/20-intel.conf"
    sudo chmod 777 /etc/X11/xorg.conf.d/20-intel.conf && printf "Section \"Device\"\n\tIdentifier \"Intel Graphics\"\n\tDriver \"Intel\"\nEndSection\0" >> /etc/X11/xorg.conf.d/20-intel.conf
    # ^ Leaving this as is due to the fact it needs to be read and accessed by the user. Don't know if it needs to write but not worth the gamble of breaking the whole config.

    #sudo pacman -S lib32-nvidia-utils #32-bit app support (multilib req, should already be configured)
    sudo mkdir /etc/pacman.d/hooks
    sudo chown $USER /etc/pacman.d/hooks #chmod 777 worked for me for all instances of this the first time
    touch /etc/pacman.d/hooks/nvidia.hook && printf "[Trigger]\nOperation=Install\nOperation=Remove\nType=Package\nTarget=nvidia\nTarget=linux\n[Action]\nDepends=mkinitcpio\nWhen=PostTransaction\nNeedsTargets\nExec=/bin/sh -c 'while read -r trg; do case \$trg in linux) exit 0; esac ; done; /usr/bin/mkinitcpio -P'\0" > /etc/pacman.d/hooks/nvidia.hook 
    #above logic avoids no upgrade of initramfs after upgrading nvidia drivers, also prevents mkinitcpio from running more than once
    sudo chown $USER -r /etc/pacman.d/hooks 
    sudo chown $USER -r /etc/X11
    sudo nvidia-xconfig 
fi

#two monitor support
#this is VERY SPECIFIC, this command syntax I use here assumes you have 2 monitors: one is HDMI connected via HDMI-1 and it is on the right (user facing) of
#a monitor connected by DVI-I-1. For my setup, the resolution defaults to 1920x1080, though I believe --mode can configure it (See "Multihead" on Arch Wiki)
#xrandr --output DVI-I-1 --auto --output HDMI-0 --auto --right-of DVI-I-1
#change primary monitor via display settings GUI of xfce (click on applications on the left of the top panel and find "Settings Manager" or "Display")
cd $HOME
[[ $USEXFCE4 = "TRUE" ]] && echo '[[ ! $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx' >> .bash_profile
[[ -f .asoundrc ]] && rm .asoundrc # its not supposed to exist
#copy settings from the system's configuration into a user-specific config (changes made in the file inside home (~) will only affect the current user and are not system wide
mkdir .pulse
cp /etc/pulse/daemon.conf .pulse/
echo flat-volumes=no >> .pulse/daemon.conf
tabs 4
#git config
git config --global user.name $GITUSER
git config --global user.email $GITMAIL
git config --global core.editor $EDITOR
#personal preference, I still have repos that use this, they screwed people over when they changed the default.
[[ ! -n $DEFAULTBRANCHNAME ]] && git config --global init.defaultBranch $DEFAULTBRANCHNAME

#vimrc
curl https://github.com/InquireWithin/configs/tree/main/dotfiles/.vimrc > .vimrc
source .vimrc

#bashrc
curl https://github.com/InquireWithin/configs/tree/main/dotfiles/.bashrc > .bashrc
source .bashrc

#xinitrc
curl https://github.com/InquireWithin/configs/tree/main/dotfiles/.xinitrc > .xinitrc
source .xinitrc

# add ~/.local/bin to path
export PATH="$PATH:$(du "$HOME/.local/bin/" | cut -f2 | tr '\n' ':' | sed 's/:*$//')"

#hosts file domain blocking (decreases the urgency of acquiring an ad-blocker and helps for browsers with limited support for ad-blocking extensions or integration)
sudo chmod 777 /etc/hosts && curl https://github.com/InquireWithin/resources/tree/main/LF/LF_extended_telemetry_list.txt >> /etc/hosts && sudo chmod 644 /etc/hosts

#remove any orphaned packages
sudo pacman --noconfirm -R $(pacman -Qtdq)

#launch the DE
[[ $USEXFCE4 = 'TRUE' ]] && startxfce4 > /dev/null 2>&1 || exec startx > /dev/null 2>&1 || xinit > /dev/null 2>&1
echo "If you're seeing this, there was one or more errors in attempting to start the X server."
sleep 2
exit 1







