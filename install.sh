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

# Partition the disks
wipefs --all /dev/vda
dd if=/dev/zero of=/dev/vda bs=1M count=100 status=progress
parted --script /dev/vda mklabel gpt
parted --script --align optimal /dev/vda mkpart "" fat32 0% 4096Mib
parted --script --align optimal /dev/vda mkpart "" btrfs 4096Mib 100%
wipefs --all /dev/vdb
dd if=/dev/zero of=/dev/vdb bs=1M count=100 status=progress
parted --script /dev/vdb mklabel gpt
parted --script --align optimal /dev/vdb mkpart "" btrfs 0% 100%
wipefs --all /dev/vdc
dd if=/dev/zero of=/dev/vdc bs=1M count=100 status=progress
parted --script /dev/vdc mklabel gpt
parted --script --align optimal /dev/vdc mkpart "" btrfs 0% 100%

# Format the partitions
mkfs.fat -F 32 /dev/vda1
mkfs.btrfs /dev/vda2
mkfs.btrfs /dev/vdb1
mkfs.btrfs /dev/vdc1

# Create the subvolumes
mount /dev/vda2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt

# Mount the file systems
mount --options compress=zstd,subvol=@ /dev/vda2 /mnt
mkdir --parents /mnt/home
mount --options compress=zstd,subvol=@home /mnt/home
mount --mkdir /dev/vda1 /mnt/boot
