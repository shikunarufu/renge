#!/bin/bash
#
# Configure Arch Linux System


# Configuration
timezone="Asia/Manila"
utflocale="en_GB.UTF-8 UTF-8"
isolocale="en_GB ISO-8859-1"
lang="en_GB.UTF-8"
consolekeyboard="us"
hostname="Renge"
rpasswd="nyanpasu"
username="Shiku"
upasswd="narufu"

# Colors
green="\033[0;32m"


# Time
echo ""${green}"Setting the time zone"
ln -sf /usr/share/zoneinfo/"${timezone}" /etc/localtime
hwclock --systohc


# Localization
echo ""${green}"Generating the locales"
sed --in-place 's/"#${utflocale}"/"${utflocale}"/' /etc/locale.gen
sed --in-place 's/"#${isolocale}"/"${isolocale}"/' /etc/locale.gen
locale-gen
echo ""${green}"Setting the system locale"
echo "LANG="${lang}"" >> /etc/locale.conf
echo ""${green}"Setting the console keyboard layout"
echo "KEYMAP="${consolekeyboard}"" >> /etc/vconsole.conf


# Network configuration
echo ""${green}"Configuring the network connection"
echo "${hostname}" >> /etc/hostname
systemctl enable NetworkManager.service


# Root password
echo ""${green}"Setting the root password"
passwd "${rpasswd}"


# Boot loader
echo ""${green}"Installing boot loader"
pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg


# User management
echo ""${green}"Adding a new user"
useradd --create-home --groups wheel "${username}"
passwd "${upasswd}"


# Reboot
echo ""${green}"Exiting the chroot environment"
exit
