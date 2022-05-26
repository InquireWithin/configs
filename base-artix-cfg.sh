#This file documents changes I made that I recall
#dates are in dd/mm/yy, time is 24h

#Init service is openrc, first installed this iteration of the os in the first week of may 2022
#Desktop env: xfce4 (startxfce4 to launch it manually)
#THIS WAS WRITTEN BEFORE I KNEW THERE WAS AN AUTOINSTALLER FOR XFCE ON THE ARTIX WIKI
#!/bin/sh
#sudo su


#provides verbosity when errors inevitably occur
set -x
CARDTYPE= #graphics card manufacturer
#graphics driver config-dependent var
numgpu=$(lspci | grep -ci vga)
([[ numgpu > 1 ]]) && echo "script currently not supported for > 1 graphics card"
#for some ungodly reason there are exactly 7 spaces prior to the string, piping into sed w/ that expression will remove preceding whitespace
[[ $(sudo lshw -C display | grep vendor | sed 's/^ *//g') == "vendor: NVIDIA Corporation" ]] && CARDTYPE="NVIDIA"
#manually configure these variables:
GITUSER= #username for git config
GITMAIL= #email for git config
PKGFILE= #filepath to manually download packages from
#either get these basic utilities or import from file

if [ -n ${PKGFILE+x} ]; then sudo pacman -S - < $PKGFILE ;else sudo pacman -Syu xfce4 xfce4-goodies zsh vim wget man gedit git artix-archlinux-support hwinfo htop unzip gnu-free-fonts ttf-liberation traceroute pulseaudio-alsa lib32-libpulse lib32-alsa-plugins

chsh -s /bin/zsh
#default editor as vim, persistently
echo "export EDITOR=/bin/vim" >> /etc/profile
sudo chmod 777 /etc/pacman.conf
#put compatibility for extra, mutilib, and community here (see software.txt)
sudo echo "[extra]\nInclude = /etc/pacman.d/mirrorlist-arch\n\n[community]\nInclude=/etc/pacman.d/mirrorlist-arch\n\n[multilib]\nInclude=/etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
sudo chmod 644 /etc/pacman.conf
pacman-key --populate archlinux
#yay installation b/c eventually I'll need an AUR exclusive package
cd /opt/
#this wont work in root or root account
sudo git clone https://aur.archlinux.org/yay-git.git && chmod 777 -r yay-git && cd yay-git && makepkg -si
cd $HOME
yay -S ttf-ms-win11
#install nvidia drivers for NV110/GMXXX series or higher (checked via nvidia driver download page)
# proprietary drivers, using for xorg (dependency of xfce)
# default linux kernel
if [ CARDTYPE == "NVIDIA" ] then
#creating a "just in case" file as the wiki said making a 20-intel.conf is preferred over xorg.conf
sudo pacman -S xf86-video-intel nvidia nvidia-settings
chmod 777 /etc/X11/xorg.conf.d/
# ^ Leaving this as is due to the fact it needs to be read and accessed by the user. Don't know if it needs to write but not worth the gamble of breaking the whole config.
sudo touch /etc/X11/xorg.conf.d/20-intel.conf
sudo chmod 777 /etc/X11/xorg.conf.d/20-intel.conf
echo "Section \"Device\"\n\tIdentifier \"Intel Graphics\"\n\tDriver \"Intel\"\nEndSection" >> /etc/X11/xorg.conf.d/20-intel.conf
#32 bit app support (multilib req)
#sudo pacman -S lib32-nvidia-utils
sudo mkdir /etc/pacman.d/hooks
sudo chown $USER:$USER /etc/pacman.d/hooks
sudo touch /etc/pacman.d/hooks/nvidia.hook
#avoids no upgrade of initramfs after upgrading nvidia drivers, also prevents mkinitcpio from running more than once
sudo echo "[Trigger]\nOperation=Install\nOperation=Remove\nType=Package\nTarget=nvidia\nTarget=linux\n[Action]\nDepends=mkinitcpio\nWhen=PostTransaction\nNeedsTargets\nExec=/bin/sh -c 'while read -r trg; do case $trg in linux) exit 0; esac ; done; /usr/bin/mkinitcpio -P'" > /etc/pacman.d/hooks/nvidia.hook 

sudo chown $USER:$USER -r /etc/pacman.d/hooks #chmod 777 worked for me for all instances of this the first time
sudo chown $USER:$USER -r /etc/X11
sudo nvidia-xconfig 
fi
#two monitor support
#this is VERY SPECIFIC, this command syntax I use here assumes you have 2 monitors: one is HDMI connected via HDMI-1 and it is on the right (user facing) of
#a monitor connected by DVI-I-1. For my setup, the resolution defaults to 1920x1080, though I believe --mode can configure it (See "Multihead" on Arch Wiki)
xrandr --output DVI-I-1 --auto --output HDMI-0 --auto --right-of DVI-I-1
#change primary monitor via display settings GUI of xfce4 (click on applications on the left of the top panel and find "Settings Manager" or "Display")

touch ~/.xinitrc && touch ~/.zshrc
echo "[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]]" >> ~/.xinitrc
[[ -f $HOME/.asoundrc ]] && rm $HOME/.asoundrc # its not supposed to exist
cd $HOME
sudo chmod u+r /etc/pulse/daemon.conf #just in case this permission isn't present
#copy settings from the system's configuration into a user-specific config (changes made in the file inside home (~) will only affect the current user and are not system wide
cp /etc/pulse/daemon.conf ~/.pulse/daemon.conf
sudo echo flat-volumes=no >> ~/.pulse/daemon.conf
#killall xfce4-panel #restart panel
#xfce4-panel &
#disown

#I hate tabs b/c it makes python an impossibility
tabs 4 #tabs should now be set to 4 spaces

#git config
git config --global user.name $GITUSER
git config --global user.email $GITMAIL
git config --global core.editor $EDITOR

#zshrc
#requires zsh-syntax-highlighting from AUR
[[ -d /usr/share/zsh/plugins/zsh-syntax-highlighting ]] && echo "source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc
echo "autoload -U colors && colors" >> ~/.zshrc
echo 'PS1="%B%{$fg[green]%}[%{$fg[blue]%}%n%{$fg[magenta]%}@%{$fg[red]%}%M %{$fg[magenta]%}%~%{$fg[green]%}]%{$reset_color%}$%b "' >> ~/.zshrc

#vimrc
#echo "set mouse=a" >> ~/.vimrc #not needed unless mouse support is disabled by default and/or you want mouse support. This depends on terminal, however.
echo "set tabstop=4" >> ~/.vimrc #vim has its own settings, so of course I want \t = to 4 spaces here as well

#bashrc













