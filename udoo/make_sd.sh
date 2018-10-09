#!/bin/bash

# partition size in MB
BOOTLOAD_RESERVE=16
BOOT_ROM_SIZE=16
SYSTEM_ROM_SIZE=1500
CACHE_SIZE=512
RECOVERY_ROM_SIZE=16
VENDER_SIZE=8
MISC_SIZE=8
# SFDISK_UNIT="M"
SFDISK_UNIT="S"

help() {

bn=`basename $0`
cat << EOF
usage $bn <option> device_node 

where:
  device_node			/dev/sdX   or   /dev/mmcblkX

options:
  -h				display this help message
EOF

}

# check the if root?
userid=`id -u`
if [ $userid -ne "0" ]; then
	echo "You're not root?"
	exit
fi

# Choose right target dir
target_dir_udoo="out/target/product/udoo_6dq"
target_dir_a62="out/target/product/a62_6dq"
target_dir_udooneo="out/target/product/udooneo_6sx"
target_dir="./"

for d in $target_dir_udoo $target_dir_a62 $target_dir_udooneo
  do
    if [ -e "$d/system.img" ]; then
       if [ -e "${target_dir}/system.img" ]; then
          if [ "${target_dir}/system.img" -ot "$d/system.img" ]; then
              target_dir=$d
          fi
       else
	    target_dir=$d
       fi
   fi
done

platform=`echo $target_dir | awk -F "/" '{print $NF}'`

endstring="uSD for Android 6.0.1 for: -> $platform <- created."

if [ ! -e "${target_dir}/boot.img" ]; then
      echo ""
      echo " --> Can't find valid images (boot.img) in target dir \"${target_dir}\". Exit."
      echo ""
      exit 1
fi

# parse command line
moreoptions=1
node="na"
part="na"
cal_only=0
flash_images=1
not_partition=0
not_format_fs=0
while [ "$moreoptions" = 1 -a $# -gt 0 ]; do
	case $1 in
	    -h) help; exit ;;
	    *)  moreoptions=0; node=$1 ;;
	esac
#	[ "$moreoptions" = 0 ] && [ $# -gt 1 ] && help && exit
	[ "$moreoptions" = 1 ] && shift
done

if [ ! -e ${node} ]; then
	help
	exit
fi


if [[ $node == /dev/sd* ]]; then
	part=${node}
else
	part=${node}p
fi

echo "Trying to unmount partitions"
umount ${part}* > /dev/null 2> /dev/null
sleep 1

# change the language to en_US for sfdisk
LANG=en_US

# call sfdisk to create partition table
# get total card size
seprate=40
total_size=`sfdisk -s ${node}`
total_size=`expr ${total_size} / 1024`
boot_rom_sizeb=`expr ${BOOT_ROM_SIZE} + ${BOOTLOAD_RESERVE}`
extend_size=`expr ${SYSTEM_ROM_SIZE} + ${CACHE_SIZE} + ${VENDER_SIZE} + ${MISC_SIZE} + ${seprate}`
data_size=`expr ${total_size} - ${boot_rom_sizeb} - ${RECOVERY_ROM_SIZE} - ${extend_size} - ${seprate}`

# echo $boot_rom_sizeb $extend_size $BOOT_ROM_SIZE $BOOTLOAD_RESERVE $SYSTEM_ROM_SIZE $MISC_SIZE $CACHE_SIZE $VENDER_SIZE $RECOVERY_ROM_SIZE $data_size
if [ ${SFDISK_UNIT} == "S" ]
  then
	sfdisk_version=`sfdisk -v | awk '{print $4}' | awk -F "." '{print $2}'`

	if [[ ${sfdisk_version} -gt 26 ]]
	 then
	   sector_size=`sfdisk -l ${node} | grep "sectors of" | awk '{print $(NF-1)}'`
	else
	   sector_size=`fdisk -l ${node} | grep "sectors of" | sed -e 's/\(.*\)=\(.*\)bytes/\2/g' | sed -e 's/\ //g'`
	fi

	(( boot_rom_sizeb = ${boot_rom_sizeb} * 1024 * 1024 / ${sector_size} ))
	(( extend_size = ${extend_size} * 1024 * 1024 / ${sector_size} ))
	(( BOOT_ROM_SIZE = ${BOOT_ROM_SIZE} * 1024 * 1024 / ${sector_size} ))
	(( BOOTLOAD_RESERVE = ${BOOTLOAD_RESERVE} * 1024 * 1024 / ${sector_size} ))
	(( SYSTEM_ROM_SIZE = ${SYSTEM_ROM_SIZE} * 1024 * 1024 / ${sector_size} ))
	(( MISC_SIZE = ${MISC_SIZE} * 1024 * 1024 / ${sector_size} ))
	(( CACHE_SIZE = ${CACHE_SIZE} * 1024 * 1024 / ${sector_size} ))
	(( VENDER_SIZE = ${VENDER_SIZE} * 1024 * 1024 / ${sector_size} ))
	(( RECOVERY_ROM_SIZE = ${RECOVERY_ROM_SIZE} * 1024 * 1024 / ${sector_size} ))
	(( data_size = ${data_size} * 1024 * 1024 / ${sector_size} ))
	(( RECOVERY_ROM_START = ${boot_rom_sizeb} ))
	(( extend_start = ${RECOVERY_ROM_START} + ${RECOVERY_ROM_SIZE} ))
	(( data_start = ${extend_start} + ${extend_size} ))
	(( SYSTEM_ROM_START = ${extend_start} + 1 ))
	(( CACHE_START = ${SYSTEM_ROM_START} + ${SYSTEM_ROM_SIZE} + 3000 ))
	(( VENDER_START = ${CACHE_START} + ${CACHE_SIZE} + 3000 ))
	(( MISC_START = ${VENDER_START} + ${VENDER_SIZE} + 3000 ))
fi
# echo $boot_rom_sizeb $extend_size $BOOT_ROM_SIZE $BOOTLOAD_RESERVE $SYSTEM_ROM_SIZE $MISC_SIZE $CACHE_SIZE $VENDER_SIZE $RECOVERY_ROM_SIZE $data_size
# exit 0

# create partitions
if [ "${cal_only}" -eq "1" ]; then
cat << EOF
BOOT   : ${boot_rom_sizeb}MB
RECOVERY: ${RECOVERY_ROM_SIZE}MB
SYSTEM : ${SYSTEM_ROM_SIZE}MB
CACHE  : ${CACHE_SIZE}MB
DATA   : ${data_size}MB
MISC   : ${MISC_SIZE}MB
EOF
exit
fi

function format_android
{
    echo "Formatting partitions..."
    metadata_opt=" -O ^metadata_csum"
    mkfs.ext4 ${metadata_opt} -F ${part}7 -Ldevice > /dev/null 2>&1
    if [ $? -ne 0 ]
      then
        metadata_opt=" "
    fi
    
    mkfs.ext4 ${metadata_opt} -F ${part}4 -Ldata
    sleep 0.5
    mkfs.ext4 ${metadata_opt} -F ${part}5 -Lsystem
    sleep 0.5
    mkfs.ext4 ${metadata_opt} -F ${part}6 -Lcache
    sleep 0.5
    mkfs.ext4 ${metadata_opt} -F ${part}7 -Ldevice
    sleep 0.5
}

function flash_android
{
    if [ "${flash_images}" -eq "1" ]; then
	echo "Flashing android images..."
	cd ${target_dir}
	dd if=u-boot.imx of=${node} bs=1k seek=1 conv=fsync
	dd if=/dev/zero of=${node} bs=1k  seek=512  count=1
	dd if=/dev/zero of=${node} bs=512 seek=1536 count=16 conv=fsync
	dd if=boot.img of=${part}1 bs=8k conv=fsync
	dd if=recovery.img of=${part}2 bs=8k conv=fsync
	[ ! -e system_raw.img ] && simg2img system.img system_raw.img
	if [ -e system.img ]; then
	    [ system.img -nt system_raw.img ] && simg2img system.img system_raw.img
	fi
	dd if=system_raw.img of=${part}5 bs=16M conv=fsync
	# Do this twice to be sure it will boot.
	sync
	fsck.ext4 -y -f ${part}5
	resize2fs ${part}5
	dd if=u-boot.imx of=${node} bs=1024 seek=1 conv=fsync
	cd -  > /dev/null 
    fi
}

if [[ "${not_partition}" -eq "1" && "${flash_images}" -eq "1" ]] ; then
    flash_android
    exit
fi


function partition_android
{
	echo "Create android partition..."
	# destroy the partition table
	dd if=/dev/zero of=${node} bs=1024 count=1

	sleep 3


	if [ ${SFDISK_UNIT} == "S" ]
	  then

	sfdisk -f -u${SFDISK_UNIT} ${node} << EOF
${BOOTLOAD_RESERVE},${BOOT_ROM_SIZE},83
${RECOVERY_ROM_START},${RECOVERY_ROM_SIZE},83
${extend_start},${extend_size},5
${data_start},${data_size},83
${SYSTEM_ROM_START},${SYSTEM_ROM_SIZE},83
${CACHE_START},${CACHE_SIZE},83
${VENDER_START},${VENDER_SIZE},83
${MISC_START},${MISC_SIZE},83
EOF
	else
	sfdisk -f -u${SFDISK_UNIT} ${node} << EOF
,${boot_rom_sizeb},83
,${RECOVERY_ROM_SIZE},83
,${extend_size},5
,${data_size},83
,${SYSTEM_ROM_SIZE},83
,${CACHE_SIZE},83
,${VENDER_SIZE},83
,${MISC_SIZE},83
EOF
	sleep 2
	sfdisk -f -u${SFDISK_UNIT} ${node} -N1 << EOF
${BOOTLOAD_RESERVE},${BOOT_ROM_SIZE},83
EOF

	fi
	sleep 1
	sfdisk -d ${node} > dump.sfdisk
}

echo ""
echo ""
echo ""
echo "############################################################################# "
echo "##                                                                         ## "
echo "## Going to format $node device. Everything on this device will be lost ## "
echo "##                                                                         ## "
echo "##  Android Distro will be grabbed from:                                   ## "
echo "##   $target_dir  ## "
echo "##                                                                         ## "
echo "############################################################################# "
echo ""
echo "  Current partition table on $node: "
echo ""
fdisk -l $node
echo ""
read -p "Continue with formatting ? (y/N)" -N 1 goon
echo ""
if [ "x$goon" != "xy" ] && [ "x$goon" != "xY" ]
  then 
   echo "Aborting"
   echo ""
   exit 0
fi

touch sfdisk.dump
sfdisk -d ${node} > /tmp/dump.sfdisk
diff -q /tmp/dump.sfdisk sfdisk.dump >/dev/null 2>&1
[[ $? -ne 0 ]] && partition_android
format_android
flash_android

echo " "
echo " "
echo -e "\t\t${endstring}"
echo " "
echo " "
echo " "


