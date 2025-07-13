#!/bin/bash
#
# Arch Linux Installation Script


# Configuration
consolekeyboard="us"
consolefont="Lat2-Terminus16"
ssd1="sdb"
hdd1="sda"


# Colors
green="\033[0;32m"


# Clear the terminal screen
echo ""${green}"Clearing the terminal screen"
clear


# Set the console keyboard layout and font
echo ""${green}"Setting the console keyboard layout"
loadkeys "${consolekeyboard}"
echo ""${green}"Setting the console font"
setfont "${consolefont}"


# Verify the boot mode
echo ""${green}"Verifying the boot mode"
bootmode=$(< /sys/firmware/efi/fw_platform_size)
if [[ "${bootmode}" == "64" ]]; then
  echo ""${green}"System is booted in UEFI mode and has a 64-bit x64 UEFI"
elif [[ "${bootmode}" == "32" ]]; then
  echo ""${green}"System is booted in UEFI mode and has a 32-bit IA32 UEFI"
else
  echo ""${green}"System may be booted in BIOS (or CSM) mode"
  echo ""${green}"Refer to your motherboard's manual"
fi


# Connect to the internet
echo ""${green}"Connecting to the internet"
ping -c 5 archlinux.org


# Update the system clock
echo ""${green}"Updating the system clock"
timedatectl set-ntp true


# Partition the disks
echo ""${green}"Partitioning the disks"
sgdisk --zap-all /dev/"${ssd1}"
sgdisk --zap-all /dev/"${hdd1}"
sgdisk --new=1:0:+1G --new=2:0:+4G --new=3:0:0 /dev/"${ssd1}"
sgdisk --new=1:0:0 /dev/"${hdd1}"
sgdisk --typecode=1:EF00 --typecode=2:8200 --typecode=3:8300 /dev/"${ssd1}"
sgdisk --typecode=1:8300  /dev/"${hdd1}"
sgdisk --change-name=1:"EFI system partition" --change-name=2:"Linux swap" --change-name=3:"Linux filesystem" /dev/"${ssd1}"
sgdisk --change-name=1:"Linux filesystem" /dev/"${hdd1}"
partprobe


# Format the partitions
echo ""${green}"Formatting the partitions"
root_partition="${ssd1}3"
home_partition="${hdd1}1"
swap_partition="${ssd1}2"
efi_system_partition="${ssd1}1"
mkfs.ext4 /dev/"${root_partition}"
mkfs.ext4 /dev/"${home_partition}"
mkswap /dev/"${swap_partition}"
mkfs.fat -F 32 /dev/"${efi_system_partition}"


# Mount the file systems
echo ""${green}"Mounting the file systems"
mount /dev/"${root_partition}" /mnt
mkdir /mnt/boot
mount /dev/"${efi_system_partition}" /mnt/boot
mkdir /mnt/home
mount /dev/"${home_partition}" /mnt/home
swapon /dev/"${swap_partition}"


# Select the mirrors
echo ""${green}"Selecting the mirrors"
reflector --save /etc/pacman.d/mirrorlist --sort rate --verbose -f 20 -l 200 -p https,http


# Install essential packages
echo ""${green}"Installing essential packages"
pacstrap -K /mnt base base-devel linux linux-firmware linux-zen linux-zen-headers amd-ucode exfatprogs ntfs-3g networkmanager neovim man-db man-pages texinfo


# Fstab
echo ""${green}"Generating an fstab file"
genfstab -U /mnt >> /mnt/etc/fstab


# Chroot
echo ""${green}"Changing root into the new system"
arch-chroot /mnt
chmod +x 2-chroot.sh
./2-chroot.sh
