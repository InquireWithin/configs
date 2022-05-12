#This file documents changes I made that I recall
#dates are in dd/mm/yy, time is 24h

#Init service is openrc, first installed this iteration of the os in the first week of may 2022
#Desktop env: xfce4 (startxfce4 to launch it manually)
#THIS WAS WRITTEN BEFORE I KNEW THERE WAS AN AUTOINSTALLER FOR XFCE ON THE ARTIX WIKI
#!/bin/sh
#sudo su



#01-06/5/22
#installed the OS and zsh
#12/5/22 script install zsh
sudo pacman -Syu zsh wget man gedit git artix-archlinux-support xf86-video-intel nvidia
chsh -s /bin/zsh
#default editor as vim, persistently
echo "export EDITOR=/bin/vim" >> /etc/profile
sudo chmod 777 /etc/pacman.conf
#put compatibility for extra, mutilib, and community here (see software.txt)
sudo echo "[extra]\nInclude = /etc/pacman.d/mirrorlist-arch\n\n[community]\nInclude=/etc/pacman.d/mirrorlist-arch\n\n[multilib]\nInclude=/etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
sudo chmod 644 /etc/pacman.conf
pacman-key --populate archlinux
#12/5/22 
#yay installation b/c eventually I'll need an AUR exclusive package
cd /opt/
sudo git clone https://aur.archlinux.org/yay-git.git && cd yay-git && makepkg -si
cd $HOME

# 12/5/22 spent ages digging the nvidia rabbithole
#install nvidia drivers for NV110/GMXXX series or higher (checked via nvidia driver download page)
# proprietary drivers, using for xorg (dependency of xfce)
# default linux kernel
#creating a "just in case" file as the wiki said making a 20-intel.conf is preferred over xorg.conf
chmod 777 /etc/X11/xorg.conf.d/
# ^ Leaving this as is due to the fact it needs to be read and accessed by the user. Don't know if it needs to write but not worth the gamble of breaking the whole config.
sudo touch /etc/X11/xorg.conf.d/20-intel.conf
sudo chmod 777 /etc/X11/xorg.conf.d/20-intel.conf
echo Section "Device"\n\tIdentifier "Intel Graphics"\n\tDriver "Intel"\nEndSection >> /etc/X11/xorg.conf.d/20-intel.conf
#32 bit app support (multilib req)
#sudo pacman -S lib32-nvidia-utils
sudo mkdir /etc/pacman.d/hooks
sudo chown $USER /etc/pacman.d/hooks
sudo touch /etc/pacman.d/hooks/nvidia.hook
#avoids no upgrade of initramfs after upgrading nvidia drivers, also prevents mkinitcpio from running more than once
sudo echo [Trigger]\nOperation=Install\nOperation=Remove\nType=Package\nTarget=nvidia\nTarget=linux\n[Action]\nDepends=mkinitcpio\nWhen=PostTransaction\nNeedsTargets\nExec=/bin/sh -c 'while read -r trg; do case $trg in linux) exit 0; esac ; done; /usr/bin/mkinitcpio -P' > /etc/pacman.d/hooks/nvidia.hook 

sudo chown $USER:$USER -r /etc/pacman.d/hooks #chmod 777 worked for me for all instances of this the first time
sudo chown $USER:$USER -r /etc/X11
sudo nvidia-xconfig 



#11/5/22
touch ~/.xinitrc
#echo [[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] >> ~/.xinitrc
sudo pacman -S pulseaudio-alsa lib32-libpulse lib32-alsa-plugins flatpak
rm ~/.asoundrc # its not supposed to exist
cd $HOME
cp /etc/pulse/daemon.conf ~/.pulse/daemon.conf
sudo echo flat-volumes=no >> ~/.pulse/daemon.conf
killall xfce4-panel #restart panel
xfce4-panel &
disown
#yay gets invalidated if ran as root user
yay -S noise-suppression-for-voice

#12/5/22
sudo pacman -S git

