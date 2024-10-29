#!/system/bin/sh
MODDIR=/data/adb/modules/susfs4ksu

SUSFS_BIN=/data/adb/ksu/bin/ksu_susfs

source ${MODDIR}/utils.sh

## sus_su ##
enable_sus_su(){
	## Create a 'overlay' folder in module root directory for storing the 'su' and sus_su_drv_path in /system/bin/ ##
	local SYSTEM_OL=${MODDIR}/overlay
	rm -rf ${SYSTEM_OL}  2>/dev/null
	mkdir -p ${SYSTEM_OL}/system_bin 2>/dev/null
	## Enable sus_su or abort the function if sus_su is not supported ##
	if ! ${SUSFS_BIN} sus_su 1; then
		return
	fi
	## Copy the new generated sus_su_drv_path and 'sus_su' to /system/bin/ and rename 'sus_su' to 'su' ##
	cp -f /data/adb/ksu/bin/sus_su ${SYSTEM_OL}/system_bin/su
	cp -f /data/adb/ksu/bin/sus_su_drv_path ${SYSTEM_OL}/system_bin/sus_su_drv_path
	## Setup permission ##
	susfs_clone_perm ${SYSTEM_OL}/system_bin /system/bin
	susfs_clone_perm ${SYSTEM_OL}/system_bin/su /system/bin/sh
	susfs_clone_perm ${SYSTEM_OL}/system_bin/sus_su_drv_path /system/bin/sh
	## Mount the overlay ##
	mount -t overlay KSU -o "lowerdir=${SYSTEM_OL}/system_bin:/system/bin" /system/bin
	## Hide the src and dest mountpoint ##
	${SUSFS_BIN} add_sus_mount ${SYSTEM_OL}/system_bin
	${SUSFS_BIN} add_sus_mount /system/bin
	## Umount it for no root granted process ##
	${SUSFS_BIN} add_try_umount /system/bin 1
}

## Enable sus_su ##
## Uncomment this if you are using kprobe hooks ksu, make sure CONFIG_KSU_SUSFS_SUS_SU config is enabled when compiling kernel ##
#enable_sus_su

## Disable susfs kernel log ##
#${SUSFS_BIN} enable_log 0

## Hexpatch prop name for newer pixel device ##
cat <<EOF >/dev/null
# Remember the length of search value and replace value has to be the same #
resetprop -n "ro.boot.verifiedbooterror" "0"
susfs_hexpatch_prop_name "ro.boot.verifiedbooterror" "verifiedbooterror" "hello_my_newworld"

resetprop -n "ro.boot.verifyerrorpart" "true"
susfs_hexpatch_prop_name "ro.boot.verifyerrorpart" "verifyerrorpart" "letsgopartyyeah"

resetprop --delete "crashrecovery.rescue_boot_count"
EOF
