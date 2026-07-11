#!/bin/bash

# Update keyrings
pacman --sync --noconfirm archlinux-keyring

# Set the console keyboard layout
loadkeys us

# Set the console font
pacman --sync --noconfirm --needed pacman-contrib terminus-font
setfont Lat2-Terminus16

# Verify the boot mode
cat /sys/firmware/efi/fw_platform_size

# Verify the internet connection
ping -c 1 ping.archlinux.org

# Update the system clock
timedatectl set-ntp true

# Select the mirrors
pacman --sync --noconfirm --needed rate-mirrors
cc=$(curl --ipv4 ifconfig.io/country_code)
rate-mirrors cachyos --save=/etc/pacman.d/mirrorlist --max-jumps=0 --entry-country="$cc" --allow-root --max-delay=21600

#######################################
# Prepare the disks
#######################################

# Install prerequisite packages
pacman --sync --noconfirm btrfs-progs

# Unmount all disks
umount --all-targets --recursive /mnt || true

# Destroy GPT and MBR data structure on all disks
sgdisk --zap-all /dev/vda
sgdisk --zap-all /dev/vdb
sgdisk --zap-all /dev/vdc

# Set sector alignment multiple to 2048 and clear all partition data
sgdisk --set-alignment=2048 --clear /dev/vda
sgdisk --set-alignment=2048 --clear /dev/vdb
sgdisk --set-alignment=2048 --clear /dev/vdc

#######################################
# Partition the disks
#######################################

# Partition 1: UEFI Boot
sgdisk --new=1::+4096MiB --typecode=1:ef00 --change-name=1:'boot' /dev/vda

# Partition 2: Root
sgdisk --new=2::-0 --typecode=2:8300 --change-name=2:'root' /dev/vda

# Partition 3: Var
sgdisk --new=1::+12G --typecode=1:8300 --change-name=1:'var' /dev/vdb

# Partition 4: Home
sgdisk --new=2::-0 --typecode=2:8300 --change-name=2:'home' /dev/vdb

# Partition 5: Data
sgdisk --new=1::-0 --typecode=1:8300 --change-name=1:'data' /dev/vdc

#######################################
# Format the partitions
#######################################

mkfs.fat -F 32 -n "boot" /dev/vda1
mkfs.btrfs --force --label "root" /dev/vda2
mkfs.btrfs --force --label "var" /dev/vdb1
mkfs.btrfs --force --label "home" /dev/vdb2
mkfs.btrfs --force --label "data" /dev/vdc1

#######################################
# Create the subvolumes
#######################################

mount -t btrfs /dev/vda2 /mnt
btrfs subvolume create /mnt/@
# Set @ as default subvolume so genfstab records subvolid=256 (not 5)
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

#######################################
# Mount the file systems
#######################################

# Mount @ subvolume
mount --options noatime,compress=zstd,ssd,commit=120,subvol=@ /dev/vda2 /mnt

# Create directories for subvolumes
mkdir --parents /mnt/var
mkdir --parents /mnt/home
mkdir --parents /mnt/data
mkdir --parents /mnt/boot

# Mount all subvolumes
mount --options noatime,compress=zstd,commit=120,subvol=@var /dev/vdb1 /mnt/var
mount --options noatime,compress=zstd,commit=120,subvol=@home /dev/vdb2 /mnt/home
mount --options noatime,compress=zstd,ssd,commit=120,subvol=@data /dev/vdc1 /mnt/data
boot_uuid=$(blkid -s UUID -o value /dev/vda1)
mount --uuid "${boot_uuid}" /mnt/boot/
