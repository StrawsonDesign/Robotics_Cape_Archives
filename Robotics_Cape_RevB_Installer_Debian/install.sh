#!/bin/bash

#Bash script to install supporting software for the Robotics Cape
# tested on beagleboard.org Debian release 4/23/2014

INSTALL_DIR="/root"
BOOTSCRIPT="Auto_Run_Script.sh"

touch *

echo " "
echo "Compiling and Installing Device Tree Overlay"
dtc -O dtb -o /lib/firmware/SD-101B-00A0.dtbo -b 0 -@ install_files/SD-101B-00A0.dts

echo "modifying uEnv.txt to Disable HDMI"
cp /boot/uboot/uEnv.txt /boot/uboot/uEnv.txt.old
echo "cape_disable=capemgr.disable_partno=BB-BONELT-HDMI,BB-BONELT-HDMIN" >> /boot/uboot/uEnv.txt

echo "Copying am335x-boneblack.dtb to change i2c bus speed"
cp /boot/uboot/dtbs/am335x-boneblack.dtb /boot/uboot/dtbs/am335x-boneblack.dtb.old
cp install_files/am335x-boneblack.dtb  /boot/uboot/dtbs/

echo "Setting Capemgr to Load Robotics Overlay by Default"
echo "CAPE=SD-101B" > /etc/default/capemgr

echo "Installing Supporting Libraries"
#echo "/usr/lib/robotics" >> /etc/ld.so.conf
cd libraries
make clean > /dev/null
make install > /dev/null
make clean
ldconfig
cd ../


echo "Installing examples, this may take a minute."
find examples/ -exec touch {} \;
cd examples
make clean > /dev/null
make install > /dev/null
make clean > /dev/null
cd ../
# chmod 755 /usr/bin/*


echo "Installing Default Calibration Files"
cp -r cape_calibration/ $INSTALL_DIR


echo "Enabling Boot Script"
cp install_files/$BOOTSCRIPT $INSTALL_DIR
rm -f /etc/init.d/$BOOTSCRIPT
ln $INSTALL_DIR/$BOOTSCRIPT /etc/init.d/$BOOTSCRIPT 
chmod 755 $INSTALL_DIR/$BOOTSCRIPT
chmod 755 /etc/init.d/$BOOTSCRIPT
update-rc.d $BOOTSCRIPT defaults 

echo " "
echo "which program should run on boot?"
echo "type 1-4 then enter"
select bfn in "balance" "blink" "none"; do
    case $bfn in
        balance ) echo "balance &" >> $INSTALL_DIR/$BOOTSCRIPT; break;;
		blink ) echo "blink &" >> $INSTALL_DIR/$BOOTSCRIPT; break;;
		none ) exit;;
    esac
done



echo
echo "Robotics Cape Configured and Installed"
echo "Reboot to complete installation."
echo

