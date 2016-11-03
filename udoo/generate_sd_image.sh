#!/bin/bash

VERSION=$(cat recovery/root/default.prop | grep "ro.build.id" | cut -d '=' -f 2)
BOARD=$(cat recovery/root/default.prop | grep "ro.product.board" | cut -d '=' -f 2)

OUTPUT=$BOARD-Android-$VERSION.img
SDSIZE=3000

BOOTLOAD_RESERVE=1
BOOT_ROM_SIZE=16
SYSTEM_ROM_SIZE=1500
CACHE_SIZE=512
RECOVERY_ROM_SIZE=16
DEVICE_SIZE=8
MISC_SIZE=6
DATAFOOTER_SIZE=2

error() {
    echo $1
    exit 1
}

echo "Creating a $SDSIZE MB image in $OUTPUT..."
dd if=/dev/zero of=$OUTPUT bs=1M count=$SDSIZE status=noxfer >/dev/null 2>&1

node=$(losetup -f)
losetup $node $OUTPUT || error "Cannot set $LOOP"

echo "Partitioning..."

LANG=en_US
seprate=40
total_size=$SDSIZE
boot_rom_sizeb=$((${BOOT_ROM_SIZE}+${BOOTLOAD_RESERVE}))
extend_size=$((${SYSTEM_ROM_SIZE} + ${CACHE_SIZE} + ${DEVICE_SIZE} + ${MISC_SIZE} + ${DATAFOOTER_SIZE} + ${seprate}))
data_size=$((${total_size} - ${boot_rom_sizeb} - ${RECOVERY_ROM_SIZE} - ${extend_size} - ${seprate}))

cat << EOF
BOOT   : ${boot_rom_sizeb}MB
RECOVERY: ${RECOVERY_ROM_SIZE}MB
SYSTEM : ${SYSTEM_ROM_SIZE}MB
CACHE  : ${CACHE_SIZE}MB
DATA   : ${data_size}MB
MISC   : ${MISC_SIZE}MB
DEVICE : ${DEVICE_SIZE}MB
DATAFOOTER : ${DATAFOOTER_SIZE}MB
EOF

parted -s $node -- mklabel msdos
partprobe $node

losetup -d "$node"
node=$(losetup -f)
losetup $node $OUTPUT || error "Cannot set $LOOP"
partprobe $node

sfdisk --force ${node} << EOF
,${boot_rom_sizeb}M,84
,${RECOVERY_ROM_SIZE}M,84
,${extend_size}M,5
,${data_size}M,83
,${SYSTEM_ROM_SIZE}M,83
,${CACHE_SIZE}M,83
,${DEVICE_SIZE}M,83
,${MISC_SIZE}M,83
,${DATAFOOTER_SIZE}M,83
EOF


losetup -d "$node"
node=$(losetup -f)
losetup $node $OUTPUT || error "Cannot set $LOOP"
partprobe $node

sfdisk --force ${node} -N1 << EOF
${BOOTLOAD_RESERVE}M,${BOOT_ROM_SIZE}M,83
EOF

losetup -d "$node"
sync

node=$(losetup -f)
losetup $node $OUTPUT || error "Cannot set $LOOP"

echo "Formatting partitions..."
mkfs.ext4 ${node}p4 -Ldata
mkfs.ext4 ${node}p5 -Lsystem
mkfs.ext4 ${node}p6 -Lcache
mkfs.ext4 ${node}p7 -Ldevice


echo "Flashing partiotions..."
dd if=u-boot.imx of=$OUTPUT bs=1k seek=1 conv=notrunc
dd if=boot.img of=${node}p1 conv=notrunc
dd if=recovery.img of=${node}p2 conv=notrunc
simg2img system.img system_raw.img
dd if=system_raw.img of=${node}p5 conv=notrunc
rm system_raw.img

sync
losetup -d "$node"

echo "Enlarging System partition..."

node=$(losetup -f)
losetup $node $OUTPUT || error "Cannot set $LOOP"

e2fsck -f -y -v -C 0 ${node}p5
sync
losetup -d "$node"
sleep 2
node=$(losetup -f)
losetup $node $OUTPUT || error "Cannot set $LOOP"
resize2fs -p ${node}p5
sleep 2
sync
losetup -d "$node"
sync

echo "Done!"

