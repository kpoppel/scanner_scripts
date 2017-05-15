# scanner_scripts
A set of scripts built on top of the Brother DCP 9010 multifunction laser printer

# Needed packages and configuration
apt-get install netpbm
apt-get install psmerge
apt-get install imagemagick
apt-get install unpaper
apt-get install cuneiform
apt-get install exactimage
apt-get install pdftk
apt-get install libsane
dpkg -i brscan3-0.2.11-5.amd64.deb
dpkg -i brother-udev-rule-type1-1.0.0-1.all.deb
apt-get install sane-utils

The Brother packages must be fetched from the Brother website.

nano /etc/default/saned
-----------------------
# Set to yes to start saned
RUN=yes

nano /etc/sane.d/saned.conf
---------------------------
192.168.0.0/24

nano /etc/inetd.conf
--------------------
sane-port       stream  tcp     nowait  saned:saned     /usr/sbin/saned saned

nano /usr/local/Brother/sane/brsanenetdevice3.cfg
-------------------------------------------------
DEVICE=DCP-9010CN , "DCP-9010CN" , 0x4f9:0x21e , IP-ADDRESS=192.168.0.200 
or use the command:
brsaneconfig3 -a name=DCP-9010CN model=DCP-9010CN ip=192.168.0.200

Grant group membership to saned user:
-------------------------------------
usermod -a -G lp,scanner saned
