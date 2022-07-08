#!/bin/sh

if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/*; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi

mv ~/.xsession-errors ~/.xsession-errors.old
exec startxfce4 > ~/.xsession-errors 2>&1
