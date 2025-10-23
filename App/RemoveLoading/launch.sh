#!/bin/sh

/customer/app/sdldisplay /mnt/SDCARD/sprig/res/sprucetree.png

DIR="$(dirname "$0")"
cd "$DIR"

{
echo "attempting to remove loading junk"
cp -r bin /tmp
cp -r lib /tmp

export PATH=/tmp/bin:$PATH
export LD_LIBRARY_PATH=/tmp/lib:$LD_LIBRARY_PATH

cd /tmp

rm -rf customer squashfs-root customer.modified

cp /dev/mtd6 customer

unsquashfs customer
if [ $? -ne 0 ]; then
	echo "unsquash failed"
	sync
	exit 1
fi

sed -i '/^\/customer\/app\/sdldisplay/d' squashfs-root/main
echo "patched main"

mksquashfs squashfs-root customer.mod -comp xz -b 131072 -xattrs -all-root
if [ $? -ne 0 ]; then
	sync
	exit 1
fi

dd if=customer.mod of=/dev/mtdblock6 bs=128K conv=fsync

} &> ./log.txt

mv "./config.json" "./config.disabled"
reboot