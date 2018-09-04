#!/bin/bash

CURR_USER=$(who | grep -o ^[a-zA-Z0-9]*" " | tr -d [:space:])
FILENAME="/home/$(CURR_USER)/Documents/scripts/log.txt"
CURRDATETIME=$(date +'%d-%m-%Y %H:%M:%S')

if [[ $UID != 0 ]]; then
	echo "root privileges required. Insert password..."
	sudo "$0" "$@"
fi

if [ ! -f "$FILENAME" ]; then
	cat > $FILENAME
fi

echo "starting upgrade at ${CURRDATETIME}" | tee -a $FILENAME
dnf upgrade -y | tee -a $FILENAME
dnf clean all | tee -a $FILENAME

if [ "$1" = "clean" ]; then
	echo "performing package clean-up" | tee -a $FILENAME
	dnf autoremove -y | tee -a $FILENAME
fi

echo "script ended at ${CURRDATETIME}" | tee -a $FILENAME
echo "===============================" >> $FILENAME

shutdown -h
