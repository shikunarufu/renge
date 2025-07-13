#!/bin/bash
#
# Arch Linux Installation Script


# Configuration
consolekeyboard="us"
consolefont="Lat2-Terminus16"
ssd1="sdb"
hdd1="sda"


# Colors
color_off="\033[0m"
green="\033[0;32m"
light_gray="\033[0;37m"
white="\033[1;37m"


# Clear the terminal screen
echo -e "         "${light_gray}"Clearing "${white}"Terminal Screen"${color_off}""
clear
echo -e ""${light_gray}"[  "${green}"OK  "${light_gray}"] Cleared "${white}"Terminal Screen"${color_off}""


# Set the console keyboard layout and font
echo -e "         "${light_gray}"Setting Console Keyboard Layout"
loadkeys "${consolekeyboard}"
echo -e ""${light_gray}"[  "${green}"OK  "${light_gray}"] Set "${white}"Console Keyboard Layout"${color_off}""
echo -e ""${green}"Setting the console font"
setfont "${consolefont}"


# Verify the boot mode
echo -e ""${green}"Verifying the boot mode"
bootmode=$(< /sys/firmware/efi/fw_platform_size)
if [[ "${bootmode}" == "64" ]]; then
  echo -e ""${green}"System is booted in UEFI mode and has a 64-bit x64 UEFI"
elif [[ "${bootmode}" == "32" ]]; then
  echo -e ""${green}"System is booted in UEFI mode and has a 32-bit IA32 UEFI"
else
  echo -e ""${green}"System may be booted in BIOS (or CSM) mode"
  echo -e ""${green}"Refer to your motherboard's manual"
fi


# Connect to the internet
echo -e ""${green}"Connecting to the internet"
ping -c 5 archlinux.org


# Update the system clock
echo -e ""${green}"Updating the system clock"
timedatectl set-ntp true


# Partition the disks
echo -e ""${green}"Partitioning the disks"
sgdisk --zap-all /dev/"${ssd1}"
sgdisk --zap-all /dev/"${hdd1}"
sgdisk --new=1:0:+1G --new=2:0:+4G --new=3:0:0 /dev/"${ssd1}"
sgdisk --new=1:0:0 /dev/"${hdd1}"
sgdisk --typecode=1:EF00 --typecode=2:8200 --typecode=3:8300 /dev/"${ssd1}"
sgdisk --typecode=1:8300  /dev/"${hdd1}"
sgdisk --change-name=1:"EFI system partition" --change-name=2:"Linux swap" --change-name=3:"Linux filesystem" /dev/"${ssd1}"
sgdisk --change-name=1:"Linux filesystem" /dev/"${hdd1}"


# Reread the partition table
sleep 2
partprobe /dev/"${ssd1}"
partprobe /dev/"${hdd1}"
sleep 2


# Format the partitions
echo -e ""${green}"Formatting the partitions"
root_partition="${ssd1}3"
home_partition="${hdd1}1"
swap_partition="${ssd1}2"
efi_system_partition="${ssd1}1"
mkfs.ext4 /dev/"${root_partition}"
mkfs.ext4 /dev/"${home_partition}"
mkswap /dev/"${swap_partition}"
mkfs.fat -F 32 /dev/"${efi_system_partition}"


# Mount the file systems
echo -e ""${green}"Mounting the file systems"
mount /dev/"${root_partition}" /mnt
mkdir /mnt/boot
mount /dev/"${efi_system_partition}" /mnt/boot
mkdir /mnt/home
mount /dev/"${home_partition}" /mnt/home
swapon /dev/"${swap_partition}"


# Select the mirrors
echo -e ""${green}"Selecting the mirrors"
reflector --save /etc/pacman.d/mirrorlist --sort rate --verbose -f 20 -l 200 -p https,http


# Install essential packages
echo -e ""${green}"Installing essential packages"
pacstrap -K /mnt base base-devel linux linux-firmware linux-zen linux-zen-headers amd-ucode exfatprogs ntfs-3g networkmanager neovim man-db man-pages texinfo


# Fstab
echo -e ""${green}"Generating an fstab file"
genfstab -U /mnt >> /mnt/etc/fstab


# Scripts
mkdir /mnt/ALIS
cp 2-chroot.sh /mnt/ALIS


# Chroot
echo -e ""${green}"Changing root into the new system"
arch-chroot /mnt
chmod +x ./ALIS/2-chroot.sh
./ALIS/2-chroot.sh
