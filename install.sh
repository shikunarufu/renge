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
umount --all-targets --recursive /mnt || true
sgdisk --zap-all /dev/vda
sgdisk --zap-all /dev/vdb
sgdisk --zap-all /dev/vdc
sgdisk --set-alignment=2048 --clear /dev/vda
sgdisk --set-alignment=2048 --clear /dev/vdb
sgdisk --set-alignment=2048 --clear /dev/vdc

# Partition the disks
sgdisk --new=1::+4096MiB --typecode=1:ef00 /dev/vda # partition 1: UEFI boot
sgdisk --new=2::-0 --typecode=2:8300 /dev/vda # partition 2: root
sgdisk --new=1::+12G --typecode=1:8300 /dev/vdb # partition 3: var
sgdisk --new=2::-0 --typecode=2:8300 /dev/vdb # partition 4: home
sgdisk --new=1::-0 --typecode=1:8300 /dev/vdc # partition 5: data

# Format the partitions
wipefs --all --force /dev/vda1
wipefs --all --force /dev/vda2
wipefs --all --force /dev/vdb1
wipefs --all --force /dev/vdb2
wipefs --all --force /dev/vdc1

mkfs.fat -F 32 /dev/vda1
mkfs.btrfs /dev/vda2
mkfs.btrfs /dev/vdb1
mkfs.btrfs /dev/vdb2
mkfs.btrfs /dev/vdc1

# Create the subvolumes
mount -t btrfs /dev/vda2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume set-default /mnt/@
umount /mnt

mount -t btrfs /dev/vdb1 /mnt
btrfs subvolume create /mnt/@var
umount /mnt

mount -t btrfs /dev/vdb2 /mnt
btrfs subvolume create /mnt/@home
umount /mnt

mount -t btrfs /dev/vdc1 /mnt
btrfs subvolume create /mnt/@data
umount /mnt

# Mount the file systems
mount --options noatime,compress=zstd,ssd,commit=120,subvol=@ /dev/vda2 /mnt
mkdir --parents /mnt/var
mount --options noatime,compress=zstd,commit=120,subvol=@var /dev/vdb1 /mnt/var
mkdir --parents /mnt/home
mount --options noatime,compress=zstd,commit=120,subvol=@home /dev/vdb2 /mnt/home
mkdir --parents /mnt/data
mount --options noatime,compress=zstd,ssd,commit=120,subvol=@data /dev/vdc1 /mnt/data
mkdir --parents /mnt/boot
boot_uuid=$(blkid -s UUID -o value /dev/vda1)
mount --uuid "${boot_uuid}" /mnt/boot/
