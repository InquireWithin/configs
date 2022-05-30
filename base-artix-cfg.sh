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
USEXFCE4="TRUE" #set up for xfce4 desktop environment
USEZSH="TRUE" #flags whether zsh should be installed and used over bash as a default shell
PKGFILE= #filepath to manually download packages from
#either get these basic utilities or import from file

if [ -n ${PKGFILE+x} ]; then sudo pacman -S --noconfirm - < $PKGFILE ;else sudo pacman -Syu --noconfirm curl vim wget man gedit git artix-archlinux-support hwinfo htop unzip gnu-free-fonts ttf-liberation traceroute pulseaudio-alsa lib32-libpulse lib32-alsa-plugins
if [ $USEZSH=="TRUE" ] then
sudo pacman -S zsh
chsh -s /bin/zsh
#zshrc
yay -S zsh-syntax-highlighting #replace this with the git process so its automated
!([[ -d /bin/curl ]]) && sudo pacman -S --noconfirm curl
curl https://github.com/InquireWithin/configs/tree/main/dotfiles/.zshrc >> ~/.zshrc
fi
if [ $USEXFCE4=="TRUE" ] then
sudo pacman -S xfce4 xfce4-goodies
fi
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
#yay -S ttf-ms-win11 #if you ever plan to use steam, uncomment

#install nvidia drivers for NV110/GMXXX series or higher (checked via nvidia driver download page)
# proprietary drivers, using for xorg (dependency of xfce)
# default linux kernel
if [ $CARDTYPE == "NVIDIA" ] then
#creating a "just in case" file as the wiki said making a 20-intel.conf is preferred over xorg.conf
sudo pacman -S xf86-video-intel nvidia nvidia-settings
[[ $USEXFCE4=="TRUE" ]] && chmod 777 /etc/X11/xorg.conf.d/ && sudo touch "/etc/X11/xorg.conf.d/20-intel.conf"
sudo chmod 777 /etc/X11/xorg.conf.d/20-intel.conf && echo "Section \"Device\"\n\tIdentifier \"Intel Graphics\"\n\tDriver \"Intel\"\nEndSection" >> /etc/X11/xorg.conf.d/20-intel.conf
# ^ Leaving this as is due to the fact it needs to be read and accessed by the user. Don't know if it needs to write but not worth the gamble of breaking the whole config.

#sudo pacman -S lib32-nvidia-utils #32-bit app support (multilib req, should already be configured)
sudo mkdir /etc/pacman.d/hooks
sudo chown $USER:$USER /etc/pacman.d/hooks #chmod 777 worked for me for all instances of this the first time
touch /etc/pacman.d/hooks/nvidia.hook && echo "[Trigger]\nOperation=Install\nOperation=Remove\nType=Package\nTarget=nvidia\nTarget=linux\n[Action]\nDepends=mkinitcpio\nWhen=PostTransaction\nNeedsTargets\nExec=/bin/sh -c 'while read -r trg; do case $trg in linux) exit 0; esac ; done; /usr/bin/mkinitcpio -P'" > /etc/pacman.d/hooks/nvidia.hook 
#above logic avoids no upgrade of initramfs after upgrading nvidia drivers, also prevents mkinitcpio from running more than once
sudo chown $USER:$USER -r /etc/pacman.d/hooks 
[[ $USEXFCE4=="TRUE" ]] && sudo chown $USER:$USER -r /etc/X11
sudo nvidia-xconfig 
fi
#two monitor support
#this is VERY SPECIFIC, this command syntax I use here assumes you have 2 monitors: one is HDMI connected via HDMI-1 and it is on the right (user facing) of
#a monitor connected by DVI-I-1. For my setup, the resolution defaults to 1920x1080, though I believe --mode can configure it (See "Multihead" on Arch Wiki)
#xrandr --output DVI-I-1 --auto --output HDMI-0 --auto --right-of DVI-I-1
#change primary monitor via display settings GUI of xfce4 (click on applications on the left of the top panel and find "Settings Manager" or "Display")


if [ $USEXFCE4 == "TRUE" ] then
echo "[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]]" >> ~/.xinitrc
fi
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
git config --global init.defaultBranch master

#vimrc
curl https://github.com/InquireWithin/configs/tree/main/dotfiles/.vimrc > ~/.vimrc
#bashrc
curl https://github.com/InquireWithin/configs/tree/main/dotfiles/.bashrc > ~/.bashrc

#hosts file domain blocking (decreases the urgency of acquiring an ad-blocker and helps for browsers with limited support for ad-blocking extensions or integration)
sudo chmod 777 /etc/hosts
curl https://raw.githubusercontent.com/InquireWithin/resources/main/ublock_adblock_server_filter.txt >> /etc/hosts
sudo chmod 644 /etc/hosts










