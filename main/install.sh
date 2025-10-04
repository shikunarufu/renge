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
ssd="vda"   # sdb
hdd="vdb"   # sda
time_zone="Asia/Manila"
utf_locale="en_GB.UTF-8 UTF-8"
iso_locale="en_GB ISO-8859-1"
language="en_GB.UTF-8"
hostname="Renge"
root_passwd="nyanpasu"
username="Shiku"
user_passwd="narufu"

#######################################
# Aesthetics
#######################################

# Clear the terminal screen
clear

# Connect to the internet
if ! ping -c 1 archlinux.org; then
  printf "%s\n" "Failed to connect to the internet"
  rm --force --recursive renge
  exit
fi

# Add developer keys
if ! pacman -S --noconfirm archlinux-keyring; then
  printf "%s\n" "Failed to add developer keys"
  rm --force --recursive renge
  exit
fi

# Install gum
if ! pacman -S --noconfirm --needed gum; then
  printf "%s\n" "Failed to install gum"
  rm --force --recursive renge
  exit
fi

# Set text color
ok_text() {
  printf "["
  printf "\e[0;32m"
  printf "  OK  "
  printf "\e[0m"
  printf "]"
  printf "\e[10G"
  if [[ $1 == *" "* ]]; then
    local text_1=${1%% *}
    local text_2=${1#* }
    printf "%s\e[1;37m%s\e[0m\n" "${text_1}" "${text_2}"
  else
    printf "%s\n" "$1"
  fi
}

# Clear the terminal screen
clear

#######################################
# Pre-Installation
#######################################

# Set the console keyboard layout and font
# loadkeys "${console_keyboard}"
gum spin --spinner dot --title "Setting console keyboard layout" -- loadkeys "${console_keyboard}"
ok_text "Set console keyboard layout"
# setfont "${console_font}"
gum spin --spinner dot --title "Setting console font" -- setfont "${console_font}"
ok_text "Set console font"

# Verify the boot mode
bootmode="$(cat /sys/firmware/efi/fw_platform_size)"
if [[ "${bootmode}" == "64" ]]; then
  printf "%s\n" "System is booted in UEFI mode and has a 64-bit x64 UEFI"
elif [[ "${bootmode}" == "32" ]]; then
  printf "%s\n" "System is booted in UEFI mode and has a 32-bit IA32 UEFI"
else
  printf "%s\n" "System may be booted in BIOS (or CSM) mode"
  printf "%s\n" "Refer to your motherboard's manual"
  rm --force --recursive renge
  exit
fi

# Connect to the internet
if ! gum spin --spinner dot --title "Setting console keyboard layout" -- ping -c 1 archlinux.org; then
  printf "%s\n" "Failed to connect to the internet"
  rm --force --recursive renge
  exit
fi

# Update the system clock
timedatectl set-ntp true

# Partition the disks
umount --all-targets --recursive /mnt
sgdisk --zap-all /dev/"${ssd}"
sgdisk --zap-all /dev/"${hdd}"
sgdisk --set-alignment=2048 --clear /dev/"${ssd}"
sgdisk --set-alignment=2048 --clear /dev/"${hdd}"
sgdisk --new=1:0:+1G --typecode=1:EF00 --change-name=1:"EFI system partition" /dev/"${ssd}"
sgdisk --new=2:0:+4G --typecode=2:8200 --change-name=2:"Linux swap" /dev/"${ssd}"
sgdisk --new=3:0:0 --typecode=3:8300 --change-name=3:"Linux filesystem" /dev/"${ssd}"
sgdisk --new=1:0:0 --typecode=1:8300 --change-name=1:"Linux filesystem" /dev/"${hdd}"
partprobe /dev/"${ssd}"
partprobe /dev/"${hdd}"

# Format the partitions
root_partition="${ssd}3"
home_partition="${hdd}1"
swap_partition="${ssd}2"
efi_system_partition="${ssd}1"
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
sed --in-place 's/#Color/Color/g' /etc/pacman.conf
sed --in-place 's/ParallelDownloads = 5/ParallelDownloads = 12/g' /etc/pacman.conf
pacman -S --noconfirm --needed archlinux-keyring
reflector --save /etc/pacman.d/mirrorlist --sort rate --threads 12 --latest 200 --protocol https,http

# Parallel compilation
core=$(grep --count ^processor /proc/cpuinfo)
sed --in-place "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$core\"/g" /etc/makepkg.conf

# Install essential packages
curl --silent --location https://raw.githubusercontent.com/shikunarufu/renge/refs/heads/main/main/pkgs/install-pacstrap-pkglist.txt >> install-pacstrap-pkglist.txt
grep --extended-regexp --only-matching '^[^(#|[:space:])]*' install-pacstrap-pkglist.txt | sort --output=install-pacstrap-pkglist.txt --unique
pacstrap -K /mnt - < install-pacstrap-pkglist.txt
rm install-pacstrap-pkglist.txt

#######################################
# Configure The System
#######################################

# Fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Prepare for chroot
cat << EOF > /mnt/configure.sh
#!/bin/bash

# Prepare for installation
sed --in-place 's/#Color/Color/g' /etc/pacman.conf
sed --in-place 's/ParallelDownloads = 5/ParallelDownloads = 12/g' /etc/pacman.conf
core=$(grep --count ^processor /proc/cpuinfo)
sed --in-place "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j\$core\"/g" /etc/makepkg.conf

# Time
ln -sf /usr/share/zoneinfo/"${time_zone}" /etc/localtime
hwclock --systohc
if ! systemctl enable systemd-timesyncd.service; then
  printf "%s\n" "Failed to enable systemd-timesyncd.service"
  exit
fi

# Localization
sed --in-place 's/#${utf_locale}/${utf_locale}/g' /etc/locale.gen
sed --in-place 's/#${iso_locale}/${iso_locale}/g' /etc/locale.gen
locale-gen
printf "%s\n" "LANG="${language}"" >> /etc/locale.conf
printf "%s\n" "KEYMAP="${console_keyboard}"" >> /etc/vconsole.conf

# Network configuration
printf "%s\n" "${hostname}" >> /etc/hostname
if ! systemctl enable NetworkManager.service; then
  printf "%s\n" "Failed to enable NetworkManager.service"
  exit
fi

# Root password
printf "%s\n%s" "${root_passwd}" "${root_passwd}" | passwd

# Users and groups
useradd --create-home --groups wheel "${username}"
printf "%s\n%s" "${user_passwd}" "${user_passwd}" | passwd "${username}"

# Security
sed --in-place 's/# %wheel/%wheel/g' /etc/sudoers
sed --in-place 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers
printf "%s\n" "Defaults passwd_timeout=0" >> /etc/sudoers

# Repositories
sed --in-place 's|#\[multilib\]|\[multilib\]|g' /etc/pacman.conf
sed --in-place '93s|#Include = /etc/pacman.d/mirrorlist|Include = /etc/pacman.d/mirrorlist|g' /etc/pacman.conf
pacman -Syu --noconfirm

# Installation
curl --silent --location https://raw.githubusercontent.com/shikunarufu/renge/refs/heads/main/main/pkgs/install-pacman-pkglist.txt >> install-pacman-pkglist.txt
grep --extended-regexp --only-matching '^[^(#|[:space:])]*' install-pacman-pkglist.txt | sort --output=install-pacman-pkglist.txt --unique
pacman -S --noconfirm --needed - < install-pacman-pkglist.txt
rm install-pacman-pkglist.txt

# Boot loader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
sed --in-place "s/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\"/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet video=efifb:off pcie_acs_override=downstream,multifunction\"/g" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# System services
if ! systemctl enable paccache.timer; then
  printf "%s\n" "Failed to enable paccache.timer"
  exit
fi
xdg-user-dirs-update
if ! systemctl enable fstrim.timer; then
  printf "%s\n" "Failed to enable fstrim.timer"
  exit
fi
EOF

# Chroot
chmod +x /mnt/configure.sh
arch-chroot /mnt /configure.sh

#######################################
# Post-Installation
#######################################

# Reboot
rm /mnt/configure.sh
umount -R /mnt
sec=10
while [[ ${sec} -gt 0 ]]; do
  printf "Restarting in $sec seconds \r"
  sleep 1
  ((sec--))
done
reboot
