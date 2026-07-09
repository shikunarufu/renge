#!/bin/bash

# Set the console keyboard layout and font
loadkeys us
setfont Lat2-Terminus16

# Verify the boot mode
cat /sys/firmware/efi/fw_platform_size

# Verify the internet connection
ping -c 1 ping.archlinux.org

# Update the system clock
timedatectl

# Prepare the disks
umount --all-targets --recursive \mnt
sgdisk --zap-all /dev/vda
sgdisk --zap-all /dev/vdb
sgdisk --zap-all /dev/vdc
sgdisk --set-alignment=2048 --clear /dev/vda
sgdisk --set-alignment=2048 --clear /dev/vdb
sgdisk --set-alignment=2048 --clear /dev/vdc

# Partition the disks
sgdisk --new=1::+4096Mib --typecode=1:ef00 /dev/vda  # Partition 1 (Boot Partition)
sgdisk --new=2::-0 --typecode=1:8300 /dev/vda        # Partition 2 (Root Partition)
sgdisk --new=3::-0 --typecode=1:8300 /dev/vdb        # Partition 3
sgdisk --new=4::-0 --typecode=1:8300 /dev/vdc        # Partition 4

# Format the partitions
mkfs.fat -F 32 /dev/vda1
mkfs.btrfs /dev/vda2
mkfs.btrfs /dev/vdb1
mkfs.btrfs /dev/vdc1

# Create the subvolumes
mount -t btrfs /dev/vda2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume set-default /mnt/@
umount /mnt

# Mount the file systems
mount --options noatime,compress=zstd,ssd,commit=120,subvol=@ /dev/vda2 /mnt
mkdir --parents /mnt/home
mount --options noatime,compress=zstd,commit=,subvol=@home /dev/vdb1 /mnt/home
mkdir --parents /mnt/boot
boot_uuid=$(blkid -s UUID -o value /dev/vda1)
mount --uuid "${boot_uuid}" /mnt/boot/
