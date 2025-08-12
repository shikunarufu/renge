#!/bin/bash
#
# Shiku's Arch Linux Installation Script

# This script automates the Arch Linux installation process
# as per the official installation guide.

# This script assumes you have already booted from an installation medium
# made from an official installation image.

# This script assumes a working internet connection is available.

# It is HIGHLY recommended to install Arch Linux 
# manually using the official installation guide.

# Uncomment the line below to show command outputs.
# set -x

#######################################
# Preparation
#######################################

# Configuration
console_keyboard="us"
console_font="Lat2-Terminus16"
ssd1="sdb"
hdd1="sda"
time_zone="Asia/Manila"
utf_locale="en_GB.UTF-8 UTF-8"
iso_locale="en_GB ISO-8859-1"
language="en_GB.UTF-8"
hostname="Renge"
root_passwd="nyanpasu"
username="Shiku"
user_passwd="narufu"

# Clear the terminal screen
clear

#######################################
# Pre-Installation
#######################################

# Set the console keyboard layout and font
loadkeys "${console_keyboard}"
setfont "${console_font}"

# Verify the boot mode
bootmode="$(cat /sys/firmware/efi/fw_platform_size)"
if [[ "${bootmode}" == "64" ]]; then
  echo "System is booted in UEFI mode and has a 64-bit x64 UEFI"
elif [[ "${bootmode}" == "32" ]]; then
  echo "System is booted in UEFI mode and has a 32-bit IA32 UEFI"
else
  echo "System may be booted in BIOS (or CSM) mode"
  echo "Refer to your motherboard's manual"
fi

# Connect to the internet
ping -c 1 archlinux.org 

# Update the system clock
timedatectl set-ntp true

# Partition the disks
umount --all-targets --recursive /mnt
sgdisk --zap-all /dev/"${ssd1}"
sgdisk --zap-all /dev/"${hdd1}"
sgdisk --set-alignment=2048 --clear /dev/"${ssd1}"
sgdisk --set-alignment=2048 --clear /dev/"${hdd1}"
sgdisk --new=1:0:+1G --typecode=1:EF00 --change-name=1:"EFI system partition" /dev/"${ssd1}"
sgdisk --new=2:0:+4G --typecode=2:8200 --change-name=2:"Linux swap" /dev/"${ssd1}"
sgdisk --new=3:0:0 --typecode=3:8300 --change-name=3:"Linux filesystem" /dev/"${ssd1}"
sgdisk --new=1:0:0 --typecode=1:8300 --change-name=1:"Linux filesystem" /dev/"${hdd1}"
partprobe /dev/"${ssd1}"
partprobe /dev/"${hdd1}"

# Format the partitions
root_partition="${ssd1}3"
home_partition="${hdd1}1"
swap_partition="${ssd1}2"
efi_system_partition="${ssd1}1"
mkfs.ext4 -F /dev/"${root_partition}"
mkfs.ext4 -F /dev/"${home_partition}"
mkswap /dev/"${swap_partition}"
mkfs.fat -F 32 /dev/"${efi_system_partition}"

# Mount the file systems
mount /dev/"${root_partition}" /mnt
mkdir /mnt/boot
mount /dev/"${efi_system_partition}" /mnt/boot
mkdir /mnt/home
mount /dev/"${home_partition}" /mnt/home
swapon /dev/"${swap_partition}"

#######################################
# Installation
#######################################

# Select the mirrors
sed --in-place 's/ParallelDownloads = 5/ParallelDownloads = 10/g' /etc/pacman.conf
pacman -S --noconfirm --needed archlinux-keyring
# reflector --save /etc/pacman.d/mirrorlist --sort rate --fastest 20 --latest 200 --protocol https,http
core=$(grep --count ^processor /proc/cpuinfo)
sed --in-place "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$core\"/g" /etc/makepkg.conf

# Install essential packages
pacstrap -K /mnt base base-devel linux linux-firmware linux-zen linux-zen-headers amd-ucode exfatprogs ntfs-3g networkmanager neovim man-db man-pages texinfo archlinux-keyring --noconfirm --needed

#######################################
# Configure The System
#######################################

# Fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Preparation for chroot
cat << EOF > /mnt/configure.sh
#!/bin/bash

# Preparation
sed --in-place 's/ParallelDownloads = 5/ParallelDownloads = 10/g' /etc/pacman.conf
core=$(grep --count ^processor /proc/cpuinfo)
sed --in-place "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j\$core\"/g" /etc/makepkg.conf

# Time
ln -sf /usr/share/zoneinfo/"${time_zone}" /etc/localtime
hwclock --systohc
systemctl enable systemd-timesyncd.service

# Localization
sed --in-place 's/#${utf_locale}/${utf_locale}/g' /etc/locale.gen
sed --in-place 's/#${iso_locale}/${iso_locale}/g' /etc/locale.gen
locale-gen
echo "LANG="${language}"" >> /etc/locale.conf
echo "KEYMAP="${console_keyboard}"" >> /etc/vconsole.conf

# Network configuration
echo "${hostname}" >> /etc/hostname
systemctl enable NetworkManager.service

# Root password
printf "%s\n%s" "${root_passwd}" "${root_passwd}" | passwd

# Repositories
sed --in-place 's|#\[multilib\]|\[multilib\]|g' /etc/pacman.conf
sed --in-place '93s|#Include = /etc/pacman.d/mirrorlist|Include = /etc/pacman.d/mirrorlist|g' /etc/pacman.conf
pacman -Syu --noconfirm

# Installation
curl --silent --location https://raw.githubusercontent.com/shikunarufu/renge/refs/heads/main/main/pkgs/install-pkglist.txt >> install-pkglist.txt
pacman -S --noconfirm --needed - < install-pkglist.txt
rm install-pkglist.txt

# Boot loader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

#######################################
# System Administration
#######################################

# Users and groups
useradd --create-home --groups wheel "${username}"
printf "%s\n%s" "${user_passwd}" "${user_passwd}" | passwd "${username}"

# Security
sed --in-place 's/# %wheel/%wheel/g' /etc/sudoers
sed --in-place 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers
echo "Defaults passwd_timeout=0" >> /etc/sudoers

#######################################
# Package Management
#######################################

# pacman
systemctl enable paccache.timer

#######################################
# Graphical User Interface
#######################################

# User directories
xdg-user-dirs-update

#######################################
# Optimization
#######################################

# Solid state drives
systemctl enable fstrim.timer
EOF

#######################################
# Chroot
#######################################

chmod +x /mnt/configure.sh
arch-chroot /mnt /configure.sh

#######################################
# Post-Installation
#######################################

# Reboot
rm /mnt/configure.sh
umount -R /mnt
