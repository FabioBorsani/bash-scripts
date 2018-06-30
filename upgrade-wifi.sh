#!/bin/bash

#script setup

reponame="rtlwifi_new"
addr="https://github.com/lwfinger/rtlwifi_new.git"

cleanup(){
	echo "interrupt received. Cleaning up"
	cd ..
	rm -r $path
	modprobe rtl8723be
}

if [[ $UID != 0 ]]; then
   echo "This script requires root permissions"
   sudo sh "$0" "$@"
   exit
fi

#actual script

if [[ "$1" = "update" || -z "$1" ]]; then
	dnf -y upgrade

	if [[ ! -d $reponame ]]; then
		git clone $addr
	fi

	dnf clean all
fi

if [ "$1" = "install" ]; then

		path="$2"
	
		if [[ -z $path || $path = "default" ]]; then
			echo "checking default path"
			if [ -d $reponame ]; then
				path=$reponame
			else
				echo "file not found!"
				exit
			fi
		fi

		cd $path

	make install

	trap cleanup SIGINT

	modprobe -rv rtl8723be

	if [ "$3" = "antenna" ]; then

		modprobe -v rtl8723be ant_sel=2
		echo "options rtl8723be ant_sel=2 fwlps=0" | tee /etc/modprobe.d/rtl8723be.conf

		modprobe -r rtl8723be
	fi

	cd ..
	rm -r $path

	modprobe rtl8723be			
fi
