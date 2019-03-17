#!/usr/bin/env bash
SERVER_IP="${1}"

if [[ -e "$SERVER_IP" ]]
then
    echo "Please set server address"
end

echo "Installing NFS client..."
apt-get install -y nfs-common

echo "Creating shared folder..."
mkdir /var/nfs
chmod 777 /var/nfs

echo "mounting nfs share..."
mount "${SERVER_IP}:/var/nfs_share/" /var/nfs
MOUNT_RECORD="${SERVER_IP}:/var/nfs_share    /var/nfs   nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0"
cp /etc/fstab /etc/fstab.backup
cat /etc/fstab sed "s/${MOUNT_RECORD}//g" > /etc/fstab
echo "${MOUNT_RECORD}" >> /etc/fstab