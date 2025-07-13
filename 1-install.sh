#!/bin/bash
#
# Arch Linux Installation Script

# Configuration
consolekeyboard="us"
consolefont="Lat2-Terminus16"
ssd1="sdb"
hdd1="sda"

timezone="Asia/Manila"
utflocale="en_GB.UTF-8 UTF-8"
isolocale="en_GB ISO-8859-1"
lang="en_GB.UTF-8"

hostname="Renge"
rpasswd="nyanpasu"
username="Shiku"
upasswd="narufu"


# Colors
color_off="\033[0m"
green="\033[0;32m"
light_gray="\033[0;37m"
white="\033[1;37m"


# Prefix
prefix1="         "${light_gray}""
prefix2=""${light_gray}"[  "${green}"OK  "${light_gray}"] "


# Clear the terminal screen
echo -e "${prefix1}Clearing "${white}"Terminal Screen"${color_off}""
clear
echo -e "${prefix2}Cleared "${white}"Terminal Screen"${color_off}""


# Set the console keyboard layout and font
echo -e "${prefix1}Setting "${white}"Console Keyboard Layout"${color_off}""
loadkeys "${consolekeyboard}"
echo -e "${prefix2}Set "${white}"Console Keyboard Layout"${color_off}""
echo -e "${prefix1}Setting "${white}"Console Font"${color_off}""
setfont "${consolefont}"
echo -e "${prefix2}Set "${white}"Console Font"${color_off}""


# Verify the boot mode
echo -e "${prefix1}Verifying "${white}"Boot Mode"${color_off}""
bootmode=$(< /sys/firmware/efi/fw_platform_size)
if [[ "${bootmode}" == "64" ]]; then
  echo -e "${prefix1}System is booted in UEFI mode and has a 64-bit x64 UEFI"${color_off}""
elif [[ "${bootmode}" == "32" ]]; then
  echo -e "${prefix1}System is booted in UEFI mode and has a 32-bit IA32 UEFI"${color_off}""
else
  echo -e "${prefix1}System may be booted in BIOS (or CSM) mode"${color_off}""
  echo -e "${prefix1}Refer to your motherboard's manual"${color_off}""
fi
echo -e "${prefix2}Verified "${white}"Boot Mode"${color_off}""


# Connect to the internet
echo -e "${prefix1}Connecting To "${white}"Internet"${color_off}""
ping -c 5 archlinux.org > /dev/null 2>&1
echo -e "${prefix2}Connected To "${white}"Internet"${color_off}""


# Update the system clock
echo -e "${prefix1}Updating "${white}"System Clock"${color_off}""
timedatectl set-ntp true
echo -e "${prefix2}Updated "${white}"System Clock"${color_off}""


# Partition the disks
echo -e "${prefix1}Partitioning "${white}"Disks"${color_off}""
sgdisk --zap-all /dev/"${ssd1}"
sgdisk --zap-all /dev/"${hdd1}"
sgdisk --new=1:0:+1G --new=2:0:+4G --new=3:0:0 /dev/"${ssd1}"
sgdisk --new=1:0:0 /dev/"${hdd1}"
sgdisk --typecode=1:EF00 --typecode=2:8200 --typecode=3:8300 /dev/"${ssd1}"
sgdisk --typecode=1:8300  /dev/"${hdd1}"
sgdisk --change-name=1:"EFI system partition" --change-name=2:"Linux swap" --change-name=3:"Linux filesystem" /dev/"${ssd1}"
sgdisk --change-name=1:"Linux filesystem" /dev/"${hdd1}"
echo -e "${prefix2}Partitioned "${white}"Disks"${color_off}""


# Reread the partition table
echo -e "${prefix1}Rereading "${white}"Partition Table"${color_off}""
sleep 2
partprobe -s /dev/"${ssd1}"
partprobe -s /dev/"${hdd1}"
sleep 2
echo -e "${prefix2}Reread "${white}"Partition Table"${color_off}""


# Format the partitions
echo -e "${prefix1}Formatting "${white}"Partitions"${color_off}""
root_partition="${ssd1}3"
home_partition="${hdd1}1"
swap_partition="${ssd1}2"
efi_system_partition="${ssd1}1"
mkfs.ext4 /dev/"${root_partition}"
mkfs.ext4 /dev/"${home_partition}"
mkswap /dev/"${swap_partition}"
mkfs.fat -F 32 /dev/"${efi_system_partition}"
echo -e "${prefix2}Formatted "${white}"Partitions"${color_off}""


# Mount the file systems
echo -e "${prefix1}Mounting "${white}"File Systems"${color_off}""
mount /dev/"${root_partition}" /mnt
mkdir /mnt/boot
mount /dev/"${efi_system_partition}" /mnt/boot
mkdir /mnt/home
mount /dev/"${home_partition}" /mnt/home
swapon /dev/"${swap_partition}"
echo -e "${prefix2}Mounted "${white}"File Systems"${color_off}""


# Select the mirrors
echo -e "${prefix1}Selecting "${white}"Mirrors"${color_off}""
#reflector --save /etc/pacman.d/mirrorlist --sort rate --verbose -f 20 -l 200 -p https,http
echo -e "${prefix2}Selected "${white}"Mirrors"${color_off}""


# Install essential packages
echo -e "${prefix1}Installing "${white}"Essential Packages"${color_off}""
pacstrap -K /mnt base base-devel linux linux-firmware linux-zen linux-zen-headers amd-ucode exfatprogs ntfs-3g networkmanager neovim man-db man-pages texinfo  > /dev/null 2>&1
echo -e "${prefix2}Installed "${white}"Essential Packages"${color_off}""


# Fstab
echo -e "${prefix1}Generating "${white}"Fstab File"${color_off}""
genfstab -U /mnt >> /mnt/etc/fstab
echo -e "${prefix2}Generated "${white}"Fstab File"${color_off}""


# Scripts
# mkdir /mnt/ALIS
# cp 2-chroot.sh /mnt/ALIS
# chmod +x /mnt/ALIS/2-chroot.sh


# Chroot
echo -e ""${green}"Changing root into the new system"
arch-chroot /mnt /bin/bash <<END
echo "hello world"
END
