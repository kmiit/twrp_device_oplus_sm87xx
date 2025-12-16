#!/sbin/sh

SCRIPTNAME="override-spl.sh"

log() {
	echo "I:$SCRIPTNAME: $1" | tee -a /dev/kmsg
	echo "I:$SCRIPTNAME: $1" | tee -a /tmp/recovery.log
}

FASTBOOTD_PROP=$(getprop ro.twrp.fastbootd)
if [ "$FASTBOOTD_PROP" = "1" ]; then
	log "Detected fastbootd (ro.twrp.fastbootd=1), exit script."
	exit 0
fi

SLOT=$(getprop ro.boot.slot_suffix)

if [ "$SLOT" = "_a" ]; then
	DYNAMICVEN="/dev/block/mapper/vendor_a"
	DYNAMICSYS="/dev/block/mapper/system_a"
elif [ "$SLOT" = "_b" ]; then
	DYNAMICVEN="/dev/block/mapper/vendor_b"
	DYNAMICSYS="/dev/block/mapper/system_b"
else
	log "No slot detected, exit script."
	exit 1
fi

log "Slot detected: $SLOT"

umount -f -l /system 2>/dev/null
log "/system unmount attempted"
umount -f -l /system_root 2>/dev/null
log "/system_root unmount attempted"
umount -f -l /vendor 2>/dev/null
log "/vendor unmount attempted"

SearchAndOverrideProp(){
	log "Creating target dir: $1"
	mkdir -p "$1"
	if [ $? -ne 0 ]; then
		log "Unable to create $1"
		exit 1
	else
		log "Mounting $2 to $1"
		mount "$2" "$1"
		if [ $? -ne 0 ]; then
			log "Failed to mount $2 to $1"
			rm -rf "$1"
			exit 1
		fi

		NEWSPL=$(find "$1" -name "build.prop" -type f -exec grep -m1 "^$3=" {} \; 2>/dev/null | head -n1 | cut -d'=' -f2)

		if [ -z "$NEWSPL" ]; then
			log "Unable to find $3"
			umount -f -l "$1" 2>/dev/null
			rm -rf "$1"
			exit 1
		else
			resetprop "$3" "$NEWSPL"
			log "Override $3 to $NEWSPL"
		fi

		umount -f -l "$1" 2>/dev/null
		log "Unmounted $1"
		rm -rf "$1"
		log "Removed $1"
	fi
}

SearchAndOverrideProp "/vendor_temp" "$DYNAMICVEN" "ro.vendor.build.security_patch"
SearchAndOverrideProp "/system_temp" "$DYNAMICSYS" "ro.build.version.security_patch"

setprop crypto.ready 1
log "crypto.ready 1"

exit 0