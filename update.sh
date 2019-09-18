#!/bin/sh
# Update an iocage jail under FreeNAS 11.2 with  mono 5.20
# https://github.com/NasKar/mono5.20

# Check for root privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Initialize Variables
JAIL_NAME=$1
POOL_PATH="/mnt/v1"
PORTS_PATH="${POOL_PATH/portsnap}"
CONFIGS_PATH=$SCRIPTPATH/configs

mkdir -p ${PORTS_PATH}/ports
mkdir -p ${PORTS_PATH}/db

iocage exec ${JAIL_NAME} service ${JAIL_NAME} stop
iocage exec ${JAIL_NAME} portsnap fetch extract
iocage exec ${JAIL_NAME} "pkg update && pkg upgrade"
iocage exec ${JAIL_NAME} "mkdir -p /mnt/configs"
iocage exec ${JAIL_NAME} "mkdir -p /usr/ports"
iocage exec ${JAIL_NAME} "mkdir -p /var/db/portsnap"


iocage fstab -a ${JAIL_NAME} ${PORTS_PATH}/ports /usr/ports nullfs rw 0 0
iocage fstab -a ${JAIL_NAME} ${PORTS_PATH}/db /var/db/portsnap nullfs rw 0 0
iocage fstab -a ${JAIL_NAME} ${CONFIGS_PATH} /mnt/configs nullfs rw 0 0
iocage exec ${JAIL_NAME} "if [ -z /usr/ports ]; then portsnap fetch extract; else portsnap auto; fi"

#iocage exec ${JAIL_NAME} cp -f /mnt/configs/mono-patch-5.20.1.34 /tmp/mono-patch-5.20.1.34

iocage exec ${JAIL_NAME} cd /usr/ports/lang/mono && patch -E < /mnt/configs/mono-patch-5.20.1.34

iocage exec ${JAIL_NAME} make -C /usr/ports/devel/llvm80 make -DBATCH install clean
iocage exec ${JAIL_NAME} make -C /usr/ports/graphics/libepoxy make -DBATCH install clean

iocage exec ${JAIL_NAME} make -C /usr/ports/lang/mono deinstall BATCH=yes
iocage exec ${JAIL_NAME} make -C /usr/ports/lang/mono reinstall BATCH=yes
iocage exec ${JAIL_NAME} make -C /usr/ports/lang/mono clean BATCH=yes

echo "Updated mono to 5.20.1.34 in ${JAIL_NAME} jail"
