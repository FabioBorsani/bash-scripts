#!/bin/bash

if [[ $UID != 0 ]]; then
	echo "root privileges required. Insert password..."
	sudo "$0" "$@"
fi

rpm -vhU https://nmap.org/dist/nmap-7.70-1.x86_64.rpm
rpm -vhU https://nmap.org/dist/zenmap-7.70-1.noarch.rpm
rpm -vhU https://nmap.org/dist/ncat-7.70-1.x86_64.rpm
rpm -vhU https://nmap.org/dist/nping-0.7.70-1.x86_64.rpm
