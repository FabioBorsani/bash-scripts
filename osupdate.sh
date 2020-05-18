#!/bin/bash

VER="$1"

if [[ $UID != 0 ]]; then
	echo "root privileges required. Insert password..."
	sudo "$0" "$@"
fi

if [[ "$VER" != "" ]]; then
	dnf upgrade --refresh
	dnf install dnf-plugin-system-upgrade
	dnf system-upgrade download --releasever="$VER" --allowerasing
	dnf system-upgrade reboot
else
	echo "please specify a Fedora version number"
	exit
fi