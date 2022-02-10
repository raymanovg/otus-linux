#! /bin/bash

echo "zero superblock"

mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}

echo "Creating raid 6 on 5 disks"

mdadm --create --verbose /dev/md0 -l 6 -n 5 /dev/sd{b,c,d,e,f}

echo "Saving mdadm.cfg"

echo "DEVICE partitions" > /etc/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm.conf
cat /etc/mdadm.conf

echo "Creating gpt on raid"

parted -s /dev/md0 mklabel gpt

echo "Creating 5 partitions on raid"

parted /dev/md0 mkpart primary ext4 0% 20%
parted /dev/md0 mkpart primary ext4 20% 40%
parted /dev/md0 mkpart primary ext4 40% 60%
parted /dev/md0 mkpart primary ext4 60% 80%
parted /dev/md0 mkpart primary ext4 80% 100%

echo "Creating file system on partitions"

for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done

echo "Creating dirs"

mkdir -p /raid/part{1,2,3,4,5}

echo "Mounting dirs to partitions"

for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done

echo "Updating fstab"

for i in $(seq 1 5); do echo "$(blkid /dev/md0p$i | awk '{ print $2}') /raid/part$i ext4 defaults 1 1" >> /etc/fstab; done 
