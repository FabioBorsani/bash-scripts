#!/bin/bash

PATH_DEVPT="/dev/sda4"
PATH_MOUNT="/mnt/windows-ntfs"
PATH_FOLDER_LOCAL="/home/fborsani/SYNC"
PATH_FOLDER_WINDS="$PATH_MOUNT/SYNC"

MOUNTED_LIST="/proc/mounts"
PATH_LOGFILE="$PATH_FOLDER_LOCAL/log.txt"
TIMESTAMP=$(date +'%d-%m-%Y %H:%M:%S')

NOSEND=0


if [[ $UID != 0 ]]; then
   echo "This script requires root permissions"
   sudo sh "$0" "$@"
   exit
fi

if [ ! -d "$PATH_FOLDER_LOCAL" ]; then
	read -p "ERROR: unable to locate local folder. Do you wish to create a new one? y/n " prompt

	if [[ "$prompt" = "y" || "$prompt" = "Y" ]]; then
		mkdir "$PATH_FOLDER_LOCAL"
		mkdir "$PATH_FOLDER_LOCAL/IN"
		mkdir "$PATH_FOLDER_LOCAL/OUT"
		chmod -R 776 "$PATH_FOLDER_LOCAL"
	else
		exit
	fi

else
	echo "local folder OK"
fi

if [ ! -f "$PATH_LOGFILE" ]; then
	cat > $PATH_LOGFILE
	echo "${TIMESTAMP} log file created" >> "$PATH_LOGFILE"
fi

echo "${TIMESTAMP} script started" >> "$PATH_LOGFILE"

if [ ! -d "$PATH_MOUNT" ]; then
	echo "WARNING: unable to locate mounted folder. Creating..." | tee -a "$PATH_LOGFILE"
	mkdir -v $PATH_MOUNT | tee -a "$PATH_LOGFILE"
	echo "access folder created" | tee -a "$PATH_LOGFILE"
else
	echo "mounted folder OK" | tee -a "$PATH_LOGFILE"
fi

if [ ! "$(ls -A $PATH_MOUNT)" ]; then
	echo "WARNING: ntfs partition not mounted. Mounting..." | tee -a "$PATH_LOGFILE"
	mount -t ntfs-3g "$PATH_DEVPT" "$PATH_MOUNT" | tee -a "$PATH_LOGFILE"
else
	echo "partition mount OK" | tee -a "$PATH_LOGFILE"
fi

if grep -q $PATH_DEVPT $MOUNTED_LIST; then
	if grep $PATH_DEVPT $MOUNTED_LIST | grep -q "\sro"; then
		echo "WARNING: partition is not writable. Will not send files." | tee -a "$PATH_LOGFILE"
		$NOSEND=1	
		
	fi
else
	echo "ERROR: partition has not been correctly mounted" | tee -a "$PATH_LOGFILE"
	exit
fi

if [ ! -d "$PATH_FOLDER_WINDS" ]; then
	echo "Windows side folder missing. Creating now" | tee -a "$PATH_LOGFILE"

	mkdir -v "$PATH_FOLDER_WINDS" | tee -a "$PATH_LOGFILE"
	mkdir -v "$PATH_FOLDER_WINDS/IN" | tee -a "$PATH_LOGFILE"
	mkdir -v "$PATH_FOLDER_WINDS/OUT" | tee -a "$PATH_LOGFILE"
	chmod -R 776 "$PATH_FOLDER_WINDS" | tee -a "$PATH_LOGFILE"
else
	echo "Windows side folder OK" | tee -a "$PATH_LOGFILE"
fi

if [ $NOSEND -eq 0 ]; then

	echo "${TIMESTAMP} Performing file copy from local folder to windows..." | tee -a "$PATH_LOGFILE"
	cp -u -r --verbose "$PATH_FOLDER_LOCAL/OUT/." "$PATH_FOLDER_WINDS/IN/" | tee -a "$PATH_LOGFILE"

fi

echo "${TIMESTAMP} Performing file copy from Windows to local folder..." | tee -a "$PATH_LOGFILE"
cp -u -r --verbose "$PATH_FOLDER_WINDS/OUT/." "$PATH_FOLDER_LOCAL/IN/" | tee -a "$PATH_LOGFILE"

echo "${TIMESTAMP} Syncronization done. Unmounting..." | tee -a "$PATH_LOGFILE"

umount -t ntfs-3g "$PATH_MOUNT"
sleep 1

if [ "$(ls -A "$PATH_MOUNT")" ]; then
	echo "WARNING: unable to unmount partition" | tee -a "$PATH_LOGFILE"

else 
	echo "${TIMESTAMP} Partition unmounted succesfully" | tee -a "$PATH_LOGFILE"
fi

echo "${TIMESTAMP} script ended successfully" | tee -a "$PATH_LOGFILE"
echo | tee -a "$PATH_LOGFILE"
