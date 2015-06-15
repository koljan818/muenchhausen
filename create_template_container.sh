#!/bin/bash

name=$1

lxc-create -n $name -t /usr/share/lxc/templates/lxc-archlinux
lxc-start -n $name
lxc-attach -n $name -- systemctl enable dhcpcd
lxc-attach -n $name -- systemctl start dhcpcd

#TODO
#Add pgbench initialization
lxc-attach -n $name -- pacman -S postgresql


