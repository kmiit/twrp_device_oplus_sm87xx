#!/sbin/sh

# The below variables shouldn't need to be changed
# unless you want to call the script something else
SCRIPTNAME="prepdecrypt"
LOGFILE=/tmp/recovery.log

#
# Override default settings
#
# If you want to force setting of osver and patchlevel to the system/vendor version,
# set the below prop in init.recovery "on init" to trigger the override function
check_setpatch_override()
{
	setpatch_prop=$(getprop $SCRIPTNAME.setpatch)
	if [ -z "$setpatch_prop" ]; then
		SETPATCH_OVERRIDE=false
	else
		SETPATCH_OVERRIDE=true
		log_print 2 "SETPATCH Override flag found."
		SETPATCH=$setpatch_prop
	fi
}
#
# Default TWRP values for PLATFORM_VERSION and PLATFORM_SECURITY_PATCH
#
# ro.build.version.release and ro.build.version.security_patch will get
# set to the below values respectively if these props are blank when
# the script runs. These values should be updated to reflect the
# TWRP defaults in your device's BoardConfig.mk
osver_twrp="99.87.36"
patchlevel_twrp="2099-12-31"

# Set default log level
DEFAULT_LOGLEVEL=1
# 0 Errors only
# 1 Errors and Information
# 2 Errors, Information, and Debugging
CUSTOM_LOGLEVEL=$(getprop $SCRIPTNAME.loglevel)
if [ -n "$CUSTOM_LOGLEVEL" ]; then
	__VERBOSE="$CUSTOM_LOGLEVEL"
else
	__VERBOSE="$DEFAULT_LOGLEVEL"
fi

# Exit codes:
# 0 Success
# 1 Unknown encryption type
# 2 Temp Mount Failure

# Function for logging to the recovery log
log_print()
{
	# 0 = Error; 1 = Information; 2 = Debugging
	case $1 in
		0|error)
			LOG_LEVEL="E"
			;;
		1|info)
			LOG_LEVEL="I"
			;;
		2|debug)
			LOG_LEVEL="DEBUG"
			;;
		*)
			LOG_LEVEL="UNKNOWN"
			;;
	esac
	if [ $__VERBOSE -ge "$1" ]; then
		echo "$LOG_LEVEL:$SCRIPTNAME::$2" >> "$LOGFILE"
	fi
}

relink()
{
	log_print 2 "Updating linker path for $1..."
	blobs=$(find "$1" -type f -exec echo '{}' \;)
	if [ -n "$blobs" ]; then
		for source in $blobs; do
			fname=$(basename "$source")
			target="/sbin/$fname"
			log_print 2 "Relinking $source to $target..."
			sed 's|/system/bin/linker|///////sbin/linker|' "$source" > "$target"
			chmod 755 "$target"
		done
	else
		log_print 2 "$1 not found. Proceeding without relinking..."
	fi
}

finish()
{
	if [ "$SETPATCH" = "true" ]; then
		is_system_mounted=$(getprop $SCRIPTNAME.system_mounted)
		if [ "$is_system_mounted" = 1 ]; then
			umount "$TEMPSYS"
			$setprop_bin $SCRIPTNAME.system_mounted 0
			rmdir "$TEMPSYS"
		fi
		if [ "$MNT_VENDOR" = "true" ]; then
			is_vendor_mounted=$(getprop $SCRIPTNAME.vendor_mounted)
			if [ "$is_vendor_mounted" = 1 ]; then
				umount "$TEMPVEN"
				$setprop_bin $SCRIPTNAME.vendor_mounted 0
				rmdir "$TEMPVEN"
			fi
		fi
	fi
	setprop crypto.ready 1
	log_print 1 "crypto.ready=$(getprop crypto.ready)"
	log_print 1 "Script complete. Device ready for decryption."
	exit 0
}

finish_error()
{
	if [ "$SETPATCH" = "true" ]; then
		is_system_mounted=$(getprop $SCRIPTNAME.system_mounted)
		if [ "$is_system_mounted" = 1 ]; then
			umount "$TEMPSYS"
			$setprop_bin $SCRIPTNAME.system_mounted 0
			rmdir "$TEMPSYS"
		fi
		if [ "$MNT_VENDOR" = "true" ]; then
			is_vendor_mounted=$(getprop $SCRIPTNAME.vendor_mounted)
			if [ "$is_vendor_mounted" = 1 ]; then
				umount "$TEMPVEN"
				$setprop_bin $SCRIPTNAME.vendor_mounted 0
				rmdir "$TEMPVEN"
			fi
		fi
	fi
	setprop crypto.ready 1
	log_print 0 "Script run incomplete. Device may not be ready for decryption."
	exit 2
}

osver_default_value()
{
	osver_default=$(grep "$1=" /"$DEFAULTPROP")
	log_print 2 "$DEFAULTPROP value: $osver_default"
}

patchlevel_default_value()
{
	patchlevel_default=$(grep "$1=" /"$DEFAULTPROP")
	log_print 2 "$DEFAULTPROP value: $patchlevel_default"
	finish
}

update_default_values()
{
	if [ -z "$1" ]; then
		log_print 0 "No $3. Checking original props..."
		if [ -n "$2" ]; then
			log_print 2 "Original $3 found. $4_orig=$2"
			log_print 2 "Setting $3 to original value..."
			$setprop_bin "$4" "$2"
			log_print 2 "Updating $DEFAULTPROP with Original $3..."
			echo "$4=$2" >> "/$DEFAULTPROP";
			$5 "$4"
		else
			log_print 0 "No Original $3 found. Setting default value..."
			osver=$osver_twrp
			patchlevel=$patchlevel_twrp
			$setprop_bin "$4" "$1"
			log_print 2 "Updating $DEFAULTPROP with default $3..."
			echo "$4=$1" >> "/$DEFAULTPROP";
			$5 "$4"
		fi
	else
		log_print 2 "$3 exists! $4=$1"
		$5 "$4"
	fi
}

check_dynamic()
{
	dynamic_partitions=$(getprop ro.boot.dynamic_partitions)
	if [ "$dynamic_partitions" = "true" ]; then
		unset suffix
	fi
}

check_encrypt()
{
	if [ "$sdkver" -ge 26 ]; then
		sleep 1
	fi
	encrypt_type=$(getprop ro.crypto.type)
	if [ "$encrypt_type" = "file" ]; then
		log_print 1 "File Based Encryption (FBE) is present."
	elif [ "$encrypt_type" = "block" ]; then
		log_print 1 "Full Device Encryption (FDE) found."
	else
		log_print 0 "Unknown decryption type or type not set. Exiting script."
		exit 1
	fi
}

check_fastboot_boot()
{
	is_fastboot_boot=$(getprop ro.boot.fastboot)
	twrpfastboot=$(grep twrpfastboot /proc/cmdline)
	skip_initramfs_present=$(grep skip_initramfs /proc/cmdline)
	if [ -n "$is_fastboot_boot" ]; then
		if [ "$SETPATCH_OVERRIDE" = "false" ]; then
			SETPATCH=false
		fi
		log_print 2 "Fastboot boot detected. ro.boot.fastboot=$is_fastboot_boot"
	elif [ -z "$is_fastboot_boot" ] && { [ -n "$twrpfastboot" ] || [ -n "$skip_initramfs_present" ]; }; then
		if [ "$SETPATCH_OVERRIDE" = "false" ]; then
			SETPATCH=false
		fi
		$setprop_bin ro.boot.fastboot 1
		is_fastboot_boot=$(getprop ro.boot.fastboot)
		log_print 2 "Fastboot boot detected. ro.boot.fastboot=$is_fastboot_boot"
	else
		log_print 2 "Recovery/Fastbootd mode boot detected."
	fi
}

check_resetprop()
{
	if [ -e /system/bin/resetprop ] || [ -e /sbin/resetprop ]; then
		log_print 2 "Resetprop binary found!"
		setprop_bin=resetprop
	else
		log_print 2 "Resetprop binary not found. Falling back to setprop."
		setprop_bin=setprop
	fi
}

temp_mount()
{
	is_mounted=$(ls -A "$1" 2>/dev/null)
	if [ -n "$is_mounted" ]; then
		log_print 1 "$2 already mounted."
	else
		mkdir "$1"
		if [ -d "$1" ]; then
			log_print 2 "Temporary $2 folder created at $1."
		else
			log_print 0 "Unable to create temporary $2 folder."
			finish_error
		fi
		mount -o ro "$3" "$1"
		is_mounted=$(ls -A "$1" 2>/dev/null)
		if [ -n "$is_mounted" ]; then
			log_print 2 "$2 mounted at $1."
			$setprop_bin $SCRIPTNAME."$2"_mounted 1
			log_print 2 "$SCRIPTNAME.$2_mounted=$(getprop "$SCRIPTNAME"."$2"_mounted)"
		else
			log_print 0 "Unable to mount $2 to temporary folder."
			finish_error
		fi
	fi
}

osver=$(getprop ro.build.version.release)
osver_orig=$(getprop ro.build.version.release_orig)
sdkver=$(getprop ro.build.version.sdk)
patchlevel=$(getprop ro.build.version.security_patch)
patchlevel_orig=$(getprop ro.build.version.security_patch_orig)

log_print 2 "Running $SCRIPTNAME script for TWRP..."
check_encrypt

log_print 2 "SDK version: $sdkver"
if [ "$sdkver" -lt 26 ]; then
	DEFAULTPROP=default.prop
	log_print 2 "Legacy device found! DEFAULTPROP variable set to $DEFAULTPROP."
else
	DEFAULTPROP=prop.default
	log_print 2 "DEFAULTPROP variable set to $DEFAULTPROP."
fi
if [ "$sdkver" -lt 29 ]; then
	venbin="/vendor/bin"
	venlib="/vendor/lib"
	abi=$(getprop ro.product.cpu.abi)
	case "$abi" in
		*64*)
			venlib="/vendor/lib64"
			log_print 2 "Device is 64-bit. Vendor library path set to $venlib."
			;;
		*)
			log_print 2 "Device is 32-bit. Vendor library path set to $venlib."
			;;
	esac
	relink "$venbin"
	relink "$venlib/libQSEEComAPI.so"
fi

ab_device=$(getprop ro.build.ab_update)

if [ -n "$ab_device" ]; then
	log_print 2 "A/B device detected! Finding current boot slot..."
	suffix=$(getprop ro.boot.slot_suffix)
	if [ -z "$suffix" ]; then
		suf=$(getprop ro.boot.slot)
		if [ -n "$suf" ]; then
			suffix="_$suf"
		fi
	fi
	log_print 2 "Current boot slot: $suffix"
fi

recpath="/dev/block/bootdevice/by-name/recovery$suffix"
check_setpatch_override
if [ -e "$recpath" ]; then
	log_print 2 "Device has recovery partition!"
	# This should only be set to true for devices with recovery-in-boot
	if [ "$SETPATCH_OVERRIDE" = "false" ]; then
		SETPATCH=false
	fi
else
	log_print 2 "No recovery partition found."
    if [ "$SETPATCH_OVERRIDE" = "false" ]; then
        SETPATCH=true
    fi
fi

if [ "$sdkver" -ge 26 ]; then
	if [ -z "$setprop_bin" ]; then
		check_resetprop
	fi

	check_fastboot_boot

	check_setpatch_override
	log_print 1 "SETPATCH=$SETPATCH"
	if [ "$SETPATCH" = false ]; then
		update_default_values "$osver" "$osver_orig" "OS version" "ro.build.version.release" osver_default_value
		update_default_values "$patchlevel" "$patchlevel_orig" "Security Patch Level" "ro.build.version.security_patch" patchlevel_default_value
	else
		log_print 2 "Build tree is Oreo or above. Proceed with setting props..."

		check_dynamic

		BUILDPROP="build.prop"
		TEMPSYS=/s
		syspath="/dev/block/bootdevice/by-name/system$suffix"

		if [ "$sdkver" -ge 29 ]; then
			SAR=true
			MNT_VENDOR=true
			TEMPVEN=/v
			venpath="/dev/block/bootdevice/by-name/vendor$suffix"

			temp_mount "$TEMPVEN" "vendor" "$venpath"

			if [ -f "$TEMPVEN/$BUILDPROP" ]; then
				log_print 2 "Vendor Build.prop exists! Reading vendor properties from build.prop..."
				vensdkver=$(grep -i -m 1 'ro.vendor.build.version.sdk=' "$TEMPVEN/$BUILDPROP"  | cut -f2 -d'=' -s)
				log_print 2 "Current vendor Android SDK version: $vensdkver"
				if [ "$vensdkver" -gt 25 ]; then
					log_print 2 "Current vendor is Oreo or above. Proceed with setting vendor security patch level..."
					venpatchlevel=$(getprop ro.vendor.build.security_patch)
					log_print 2 "Current Vendor Security Patch Level: $venpatchlevel"
					venpatchlevel_device=$(grep -i -m 1 'ro.vendor.build.security_patch=' "$TEMPVEN/$BUILDPROP"  | cut -f2 -d'=' -s)
					if ! [ "$venpatchlevel" = "venpatchlevel_device" ]; then
						$setprop_bin "ro.vendor.build.security_patch" "$venpatchlevel_device"
						sed -i "s/ro.vendor.build.security_patch=.*/ro.vendor.build.security_patch=""$venpatchlevel_device""/g" "/$DEFAULTPROP" ;
						venpatchlevel_new=$(getprop ro.vendor.build.security_patch)
						venpatchlevel_default=$(grep -i -m 1 'ro.vendor.build.security_patch=' /$DEFAULTPROP | cut -f2 -d'=' -s)
						if [ "$venpatchlevel_device" = "$venpatchlevel_new" ]; then
							log_print 2 "$setprop_bin successful! New Vendor Security Patch Level: $venpatchlevel_new"
						else
							log_print 0 "$setprop_bin failed. Vendor Security Patch Level unchanged."
						fi
						if [ "$venpatchlevel_device" = "$venpatchlevel_default" ]; then
							log_print 2 "$DEFAULTPROP update successful! ro.vendor.build.security_patch=$venpatchlevel_default"
						else
							log_print 0 "$DEFAULTPROP update failed. Vendor Security Patch Level unchanged."
						fi
					else
						venpatchlevel_default=$(grep -i -m 1 'ro.vendor.build.security_patch=' /$DEFAULTPROP | cut -f2 -d'=' -s)
						if ! [ "$venpatchlevel_device" = "$venpatchlevel_default" ]; then
							sed -i "s/ro.vendor.build.security_patch=.*/ro.vendor.build.security_patch=""$venpatchlevel_device""/g" "/$DEFAULTPROP" ;
						fi
					fi
				else
					log_print 2 "Current vendor is Nougat or older. Skipping vendor security patch level setting..."
				fi
			fi
		else
			SAR=$(getprop ro.build.system_root_image)
		fi

		if [ "$SAR" = "true" ]; then
			log_print 2 "System-as-Root device detected! Updating build.prop path variable..."
			BUILDPROP="system/build.prop"
			log_print 2 "Build.prop location set to $BUILDPROP."
		fi

		temp_mount "$TEMPSYS" "system" "$syspath"

		if [ -f "$TEMPSYS/$BUILDPROP" ]; then
			log_print 2 "Build.prop exists! Reading system properties from build.prop..."
			sdkver=$(grep -i -m 1 'ro.build.version.sdk=' "$TEMPSYS/$BUILDPROP"  | cut -f2 -d'=' -s)
			log_print 2 "Current system Android SDK version: $sdkver"
			if [ "$sdkver" -gt 25 ]; then
				log_print 2 "Current system is Oreo or above. Proceed with setting OS Version & Security Patch Level..."
				log_print 2 "Current OS Version: $osver"
				osver=$(grep -i -m 1 'ro.build.version.release=' "$TEMPSYS/$BUILDPROP"  | cut -f2 -d'=' -s)
				if [ -n "$osver" ]; then
					$setprop_bin "ro.build.version.release" "$osver"
					sed -i "s/ro.build.version.release=.*/ro.build.version.release=""$osver""/g" "/$DEFAULTPROP" ;
					osver_new=$(getprop ro.build.version.release)
					osver_default=$(grep -i -m 1 'ro.build.version.release=' /$DEFAULTPROP | cut -f2 -d'=' -s)
					if [ "$osver" = "$osver_new" ]; then
						log_print 2 "$setprop_bin successful! New OS Version: $osver_new"
					else
						log_print 0 "$setprop_bin failed. OS Version unchanged."
					fi
					if [ "$osver" = "$osver_default" ]; then
						log_print 2 "$DEFAULTPROP update successful! ro.build.version.release=$osver_default"
					else
						log_print 0 "$DEFAULTPROP update failed. OS Version unchanged."
					fi
				fi
				log_print 2 "Current Security Patch Level: $patchlevel"
				patchlevel=$(grep -i -m 1 'ro.build.version.security_patch=' "$TEMPSYS/$BUILDPROP"  | cut -f2 -d'=' -s)
				if [ -n "$patchlevel" ]; then
					$setprop_bin "ro.build.version.security_patch" "$patchlevel"
					sed -i "s/ro.build.version.security_patch=.*/ro.build.version.security_patch=""$patchlevel""/g" "/$DEFAULTPROP" ;
					patchlevel_new=$(getprop ro.build.version.security_patch)
					patchlevel_default=$(grep -i -m 1 'ro.build.version.security_patch=' /$DEFAULTPROP | cut -f2 -d'=' -s)
					if [ "$patchlevel" = "$patchlevel_new" ]; then
						log_print 2 "$setprop_bin successful! New Security Patch Level: $patchlevel_new"
					else
						log_print 0 "$setprop_bin failed. Security Patch Level unchanged."
					fi
					if [ "$patchlevel" = "$patchlevel_default" ]; then
						log_print 2 "$DEFAULTPROP update successful! ro.build.version.security_patch=$patchlevel_default"
					else
						log_print 0 "$DEFAULTPROP update failed. Security Patch Level unchanged."
					fi
				fi
				finish
			else
				log_print 2 "Current vendor is Nougat or older. Skipping vendor security patch level setting..."
				finish
			fi
		fi
	fi
else
	log_print 2 "Build tree is Nougat or older. Skip setting props."
	finish
fi
