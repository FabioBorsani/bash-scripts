#!/bin/bash

PATH_DEVPT="/dev/sda3"
PATH_MOUNT="/mnt/windows-ntfs"


CURR_USER=$(who | grep -o ^[a-zA-Z0-9]*" " | tr -d [:space:])

PATH_FOLDER_LOCAL="/home/${CURR_USER}/SYNC"
PATH_FOLDER_WINDS="$PATH_MOUNT/SYNC"

MOUNTED_LIST="/proc/mounts"
PATH_LOGFILE="$PATH_FOLDER_LOCAL/log.txt"
TIMESTAMP=$(date +'%d-%m-%Y %H:%M:%S')

NOSEND=0
SKIP_UNMOUNT=0

if [[ $UID != 0 ]]; then
   echo "This script requires root permissions"
   sudo sh "$0" "$@"
   exit
fi

case "$1" in
  "-ch")
  rm -rf "$PATH_LOGFILE"
  echo "log file removed"
  exit
  ;;
  "-cl")
  rm -rf "$PATH_FOLDER_LOCAL/IN/*"
  rm -rf "$PATH_FOLDER_LOCAL/OUT/*"
  echo "local folders cleared"
  exit
  ;;
  "-ca")
  rm -rf "$PATH_FOLDER_LOCAL/IN/*"
  rm -rf "$PATH_FOLDER_LOCAL/OUT/*"
  rm -rf "$PATH_LOGFILE"
  echo "logs and local folders cleared"
  exit
  ;;
  "--force-close")
  umount -t ntfs-3g "$PATH_MOUNT"
  echo "driver in default position unmounted"
  exit
  ;;
esac

command -v ntfs-3g >/dev/null 2>&1 || { echo >&2 "ERROR: ntfs-3g package requested. Aborting"; exit; }

if [ ! -d "$PATH_FOLDER_LOCAL" ]; then
	read -p "ERROR: unable to locate local folder. Do you wish to create a new one? y/n " prompt

	if [[ "$prompt" = "y" || "$prompt" = "Y" ]]; then
		mkdir "$PATH_FOLDER_LOCAL"
		mkdir "$PATH_FOLDER_LOCAL/IN"
		mkdir "$PATH_FOLDER_LOCAL/OUT"
		chmod -R 750 "$PATH_FOLDER_LOCAL"
	else
		exit
	fi

else
	echo "local folder OK"
fi

if [ ! -f "$PATH_LOGFILE" ]; then
	touch "$PATH_LOGFILE"
  chown "$CURR_USER":"$CURR_USER" "$PATH_LOGFILE"
	echo "${TIMESTAMP} log file created" >> "$PATH_LOGFILE"
fi

echo "${TIMESTAMP} script started" >> "$PATH_LOGFILE"

if [ ! -d "$PATH_MOUNT" ]; then
	echo "unable to locate mounted folder. Creating..." | tee -a "$PATH_LOGFILE"
	mkdir -v $PATH_MOUNT | tee -a "$PATH_LOGFILE"
	echo "access folder created" | tee -a "$PATH_LOGFILE"
else
	echo "mounted folder OK" | tee -a "$PATH_LOGFILE"
fi

if mount | grep -q "$PATH_DEVPT"; then
  echo "WARNING: partition is already mounted." | tee -a "$PATH_LOGFILE"
  PATH_MOUNT_TEMP="$(mount | grep "$PATH_DEVPT" | grep -o "on /"[a-zA-Z0-9/]* | grep -o "/"[a-zA-Z0-9/]*$)"

  if [ "$PATH_MOUNT" != "$PATH_MOUNT_TEMP" ]; then
    PATH_MOUNT="$PATH_MOUNT_TEMP"
    echo "mount point switched to ${PATH_MOUNT}" | tee -a "$PATH_LOGFILE"
    SKIP_UNMOUNT=1
  fi

else
  if [ ! "$(ls -A $PATH_MOUNT)" ]; then
  	echo "ntfs partition not mounted. Mounting..." | tee -a "$PATH_LOGFILE"
  	mount -t ntfs-3g "$PATH_DEVPT" "$PATH_MOUNT" | tee -a "$PATH_LOGFILE"
  else
  	echo "partition mount OK" | tee -a "$PATH_LOGFILE"
  fi
fi

if grep -q $PATH_DEVPT $MOUNTED_LIST; then
	if grep $PATH_DEVPT $MOUNTED_LIST | grep -q "\sro"; then
		echo "WARNING: partition is not writable. Will not send files." | tee -a "$PATH_LOGFILE"
		NOSEND=1
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

  if [ "$1" = "-rl" ]; then
    echo "${TIMESTAMP} Cleaning local folder" | tee -a "$PATH_LOGFILE"
    rm -rf "$PATH_FOLDER_LOCAL/OUT/*"
  fi
fi

echo "${TIMESTAMP} Performing file copy from Windows to local folder..." | tee -a "$PATH_LOGFILE"
cp -u -r --verbose "$PATH_FOLDER_WINDS/OUT/." "$PATH_FOLDER_LOCAL/IN/" | tee -a "$PATH_LOGFILE"

if [ "$1" = "-rr" ]; then
  echo "${TIMESTAMP} Cleaning remote folder" | tee -a "$PATH_LOGFILE"
  rm -rf "$PATH_FOLDER_WINDS/OUT/*"
fi

chown -R --verbose "$CURR_USER":"$CURR_USER" "$PATH_FOLDER_LOCAL/IN" | tee -a "$PATH_LOGFILE"

if [ $SKIP_UNMOUNT -eq 0 ]; then
  echo "${TIMESTAMP} Syncronization done. Unmounting..." | tee -a "$PATH_LOGFILE"

  umount -t ntfs-3g "$PATH_MOUNT"
  sleep 1

  if [ "$(ls -A "$PATH_MOUNT")" ]; then
  	echo "ERROR: unable to unmount partition" | tee -a "$PATH_LOGFILE"
    exit
  else
  	echo "${TIMESTAMP} Partition unmounted succesfully" | tee -a "$PATH_LOGFILE"
  fi
else
  echo "${TIMESTAMP} Syncronization done. Skipping unmount (partition is in use by another user)" | tee -a "$PATH_LOGFILE"
fi

echo "${TIMESTAMP} script ended successfully" | tee -a "$PATH_LOGFILE"
echo | tee -a "$PATH_LOGFILE"
