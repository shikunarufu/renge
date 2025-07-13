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


# Time
echo "Setting the time zone"
ln -sf /usr/share/zoneinfo/"${timezone}" /etc/localtime
hwclock --systohc


# Localization
echo "Generating the locales"
sed --in-place 's/"#${utflocale}"/"${utflocale}"/' /etc/locale.gen
sed --in-place 's/"#${isolocale}"/"${isolocale}"/' /etc/locale.gen
locale-gen
echo "Setting the system locale"
echo "LANG="${lang}"" >> /etc/locale.conf
echo "Setting the console keyboard layout"
echo "KEYMAP="${consolekeyboard}"" >> /etc/vconsole.conf


# Network configuration
echo "Configuring the network connection"
echo "${hostname}" >> /etc/hostname
systemctl enable NetworkManager.service


# Root password
echo "Setting the root password"
passwd "${rpasswd}"


# Boot loader
echo "Installing boot loader"
pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg


# User management
echo "Adding a new user"
useradd --create-home --groups wheel "${username}"
passwd "${upasswd}"


# Reboot
echo "Exiting the chroot environment"
exit
