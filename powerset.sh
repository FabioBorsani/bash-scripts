#!/bin/bash

VGA="/sys/kernel/debug/vgaswitcheroo/switch"
PCI_list="/sys/bus/pci/devices/*/power/control"
SATA_list="/sys/class/scsi_host/*/link_power_management_policy"
I2C_list="/sys/bus/i2c/devices/*/device/power/control"
USB_list="/sys/bus/usb/devices/*/power/control"
USB_EXT_list="/sys/bus/usb/devices/usb*/power/control"
HDAUDIO_list="/sys/bus/hdaudio/devices/*/power/control"

WATCHDOG="/proc/sys/kernel/nmi_watchdog"
WRITEBACK="/proc/sys/vm/dirty_writeback_centisecs"

CHARGER="/sys/class/power_supply/ACAD"
BATTERY="/sys/class/power_supply/BAT1"

ACAD=$(<"$CHARGER/online")

if [ -d "$BATTERY" ]; then
	STATUS=$(<"$BATTERY/status")
	CHARGE=$(<"$BATTERY/capacity")
	BATT=$(<"$BATTERY/present")
fi

WRITEBACK_default=500		#write every 5 secs	
WRITEBACK_medium=1500		#write every 15 secs
WRITEBACK_long=3000		#write every 30 secs
WRITEBACK_very_long=6000	#write every minute

ERROR_F(){
	echo "ERROR: $1 .Terminating..."
	exit
}

setGpu(){
	if [ "$1" = "igd" ]; then
		echo ON > $VGA
		echo IGD > $VGA
		echo OFF > $VGA
	elif [ "$1" = "dis" ]; then
		echo ON > $VGA
		echo DIS > $VGA
		echo OFF > $VGA
	else
		ERROR_F "incorrect input in VGA switcher"
	fi
}

setWatchDog(){
	if [[ "$1" = "on" || "$1" = "1" ]]; then echo "1" > $WATCHDOG		
	elif [[ "$1" = "off" || "$1" = "0" ]]; then echo "0" > $WATCHDOG		
	else ERROR_F "incorrect input in watchdog settings"
	fi
}

setWriteBackTime(){
	case "$1" in
		"default") echo "$WRITEBACK_default" > $WRITEBACK ;;
		"medium") echo "$WRITEBACK_medium" > $WRITEBACK ;;
		"long") echo "$WRITEBACK_long" > $WRITEBACK ;;
		"llong") echo "$WRITEBACK_very_long" > $WRITEBACK ;;
		*) ERROR_F "incorrect input in writeback time settings" ;;
	esac		
}

setSataPwr(){
	case "$1" in
		"max") echo "max_performance" | tee $SATA_list ;;
		"med") echo "medium_power" | tee $SATA_list ;;
		"min") echo "min_power" | tee $SATA_list ;;
		*) ERROR_F "incorrect input in SATA power settings" ;;
	esac
}

setPower(){
	case "$1" in
		"max")
			echo "on" | tee $PCI_list
			echo "on" | tee $USB_list
			echo "on" | tee $I2C_list
			echo "on" | tee $HDAUDIO_list
			setWatchDog on
			setWriteBackTime default
			setSataPwr max
			setGpu dis
		;;
		
		"auto")
			echo "auto" | tee $PCI_list
			echo "auto" | tee $USB_list
			echo "auto" | tee $I2C_list
			echo "auto" | tee $HDAUDIO_list
			setWatchDog on
			setWriteBackTime default
			setSataPwr max
			setGpu igd
		;;
	
		"med")
			echo "auto" | tee $PCI_list
			echo "auto" | tee $USB_list
			echo "auto" | tee $I2C_list
			echo "auto" | tee $HDAUDIO_list
			setWatchDog on
			setWriteBackTime medium
			setSataPwr med
			setGpu igd
		;;
	
		"low")
			echo "auto" | tee $PCI_list
			echo "auto" | tee $USB_list
			echo "auto" | tee $I2C_list
			echo "auto" | tee $HDAUDIO_list
			setWatchDog off
			setSataPwr min
			setGpu igd
			
			if [ "$2" = "long-timeout" ]; then setWriteBackTime llong
			else setWriteBackTime long
			fi	
		;;
	
		*) ERROR_F "power setting $1 does not exist" ;;
	esac
}

powerManager(){

	if [ "$ACAD" = "1" ]; then
		if [ -d "$BATTERY" ]; then
			case "$STATUS" in
				"Charging") setPower auto ;;
				"Full") setPower max ;;
				*) echo ERROR_F "unable to read battery status"
			esac 
		else setPower max
		fi
	elif [ "$ACAD" = "0" ]; then
		if [ $CHARGE -gt 60 ]; then setPower auto
		elif [ $CHARGE -gt 20 ]; then setPower med
		elif [ $CHARGE -gt 0 ]; then setPower low
		else ERROR_F "unable to read battery charge"
		fi
	else ERROR_F "unable to read power settings"
	fi
}

showData(){
	echo
	echo "***power supply***"
	echo "ACAD: $ACAD"

	if [ "$BATT" = "1" ]; then echo "BATT: $BATT charge: $CHARGE status: $STATUS"
	else echo "BATT: 0 charge: --- status: ---"
	fi

	echo
	echo "***VGA switcher status***"
	cat $VGA
	echo
	echo "***SATA power settings***"
	cat $SATA_list
	echo
	echo "***audio power settings***"
	cat $HDAUDIO_list
	echo
	echo "***safety settings***"
	echo "watchdog: $(<$WATCHDOG)"
	echo "writeback time: $(<$WRITEBACK) centisecs"
	echo

	#echo "***connectors power settings***"
	#echo "PCI:"
	#cat $PCI_list
	#echo "I2C_list:"
	#cat $I2C_list
	#echo "USB:"
	#cat $USB_list
}


if [[ $UID != 0 ]]; then ERROR_F "this script requires root permission"
fi

if [[ "$1" = "-show" || -z "$1" ]]; then showData

elif [ "$1" = "-set" ]; then
	case "$2" in
		"power") setPower "$3" ;;
		"gpu") setGpu "$3" ;;
		"sata") setSataPwr "$3" ;;
		"watchdog") setWatchDog "$3" ;;
		"writeback") setWriteBackTime "$3" ;;
		*) ERROR_F "command $2 doesnt exist";;
	esac

elif [ "$1" = "-force-usb-on" ]; then echo "on" | tee $USB_EXT_list
elif [ "$1" = "-force-hdaudio-on" ]; then echo "on" | tee $HDAUDIO_list
else ERROR_F "command $1 doesnt exist"
fi
