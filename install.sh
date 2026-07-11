#!/bin/bash
#
# Renge (Arch Linux Installation Script)

# Verify the internet connection
ping -c 1 ping.archlinux.org

# Update Arch Linux keyring
pacman --sync --refresh
pacman --sync --noconfirm archlinux-keyring

# Install CachyOS keyring
pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com
pacman-key --lsign-key F3B607488DB35A47

# Install CachyOS repositories
pacman --upgrade --noconfirm 'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-keyring-20240331-1-any.pkg.tar.zst' \
'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-v3-mirrorlist-27-1-any.pkg.tar.zst'
pacman --sync --refresh

# Set the console keyboard layout
loadkeys us

# Set the console font
pacman --sync --noconfirm --needed pacman-contrib terminus-font
setfont Lat2-Terminus16

# Verify the boot mode
cat /sys/firmware/efi/fw_platform_size

# Update the system clock
timedatectl set-ntp true

# Select the mirrors
pacman --sync --noconfirm --needed rate-mirrors
country="$(curl --ipv4 ifconfig.io/country_code)"
rate-mirrors --save=/etc/pacman.d/mirrorlist --max-jumps=0 --entry-country="${country}" --allow-root arch
rate-mirrors --save=/etc/pacman.d/cachyos-mirrorlist --max-jumps=0 --entry-country="${country}" --allow-root cachyos

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
boot_uuid="$(blkid -s UUID -o value /dev/vda1)"
mount --uuid "${boot_uuid}" /mnt/boot/

#######################################
# Installation
#######################################

# Configure pacman
sed --in-place 's/#Color/Color/g' /etc/pacman.conf
sed --in-place '/Color/a ILoveCandy' /etc/pacman.conf
sed --in-place 's/CheckSpace/#CheckSpace/g' /etc/pacman.conf
sed --in-place 's/#VerbosePkgLists/VerbosePkgLists/g' /etc/pacman.conf
thread="$(nproc)"
sed --in-place "s/ParallelDownloads = 5/ParallelDownloads = $thread/g" /etc/pacman.conf
sed --in-place '/#DisableSandboxSyscalls/a DisableDownloadTimeout' /etc/pacman.conf

# Append multilib repository
sed --in-place 's|#\[multilib\]|\[multilib\]|g' /etc/pacman.conf
sed --in-place '96s|#Include = /etc/pacman.d/mirrorlist|Include = /etc/pacman.d/mirrorlist|g' /etc/pacman.conf

# Append CachyOS repositories
sed --in-place '76 a [cachyos-v3]' /etc/pacman.conf
sed --in-place '77 a Include = /etc/pacman.d/cachyos-v3-mirrorlist' /etc/pacman.conf
sed --in-place '78 a \\' /etc/pacman.conf
sed --in-place '79 a [cachyos-core-v3]' /etc/pacman.conf
sed --in-place '80 a Include = /etc/pacman.d/cachyos-v3-mirrorlist' /etc/pacman.conf
sed --in-place '81 a \\' /etc/pacman.conf
sed --in-place '82 a [cachyos-extra-v3]' /etc/pacman.conf
sed --in-place '83 a Include = /etc/pacman.d/cachyos-v3-mirrorlist' /etc/pacman.conf
sed --in-place '84 a \\' /etc/pacman.conf

# Parallel compilation
core=$(grep --count ^processor /proc/cpuinfo)
sed --in-place "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$core\"/g" /etc/makepkg.conf

# Install essential packages
grep --extended-regexp --only-matching '^[^(#|[:space:])]*' ./renge/pkgs/install-pacstrap-pkglist.txt \
  | sort --output=./renge/pkgs/install-pacstrap-pkglist.txt --unique
pacstrap -K /mnt - < ./renge/pkgs/install-pacstrap-pkglist.txt
