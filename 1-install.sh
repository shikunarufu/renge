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

# Uncomment the line below for debugging.
set -x

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

# Aesthetics
entry_status() {
  printf "\e[10G"
  if [[ $1 == *" "* ]]; then
    local subject=${1%% *}
    local predicate=${1#* }
    printf "%s \e[1;37m%s\e[0m\n" "${subject}" "${predicate}"
  else
    printf "%s\n" "$1"
  fi
}
info_status() {
  printf "\e[10G"
  local text="$1"
  printf "%s\n" "$1"
}
exit_status() {
  printf "["
  printf "\e[0;32m"
  printf "  OK  "
  printf "\e[0m"
  printf "]"
  printf "\e[10G"
  if [[ $1 == *" "* ]]; then
    local subject=${1%% *}
    local predicate=${1#* }
    printf "%s \e[1;37m%s\e[0m\n" "${subject}" "${predicate}"
  else
    printf "%s\n" "$1"
  fi
}

# Clear the terminal screen
#entry_status "Clearing Terminal Screen"
clear
#exit_status "Cleared Terminal Screen"

#######################################
# Pre-Installation
#######################################

# Set the console keyboard layout and font
#entry_status "Setting Console Keyboard Layout"
loadkeys "${console_keyboard}"
#exit_status "Set Console Keyboard Layout to ${console_keyboard}"
#entry_status "Setting Console Font"
setfont "${console_font}"
#exit_status "Set Console Font to ${console_font}"

# Verify the boot mode
#entry_status "Verifying Boot Mode"
bootmode="$(cat /sys/firmware/efi/fw_platform_size)"
if [[ "${bootmode}" == "64" ]]; then
  echo "System is booted in UEFI mode and has a 64-bit x64 UEFI"
elif [[ "${bootmode}" == "32" ]]; then
  echo "System is booted in UEFI mode and has a 32-bit IA32 UEFI"
else
  echo "System may be booted in BIOS (or CSM) mode"
  echo "Refer to your motherboard's manual"
fi
#exit_status "Verified Boot Mode"

# Connect to the internet
#entry_status "Connecting to Internet"
ping -c 5 archlinux.org
#exit_status "Connected to Internet"

# Update the system clock
#entry_status "Updating System Clock"
timedatectl set-ntp true
#exit_status "Updated System Clock"

# Partition the disks
#entry_status "Partitioning Disks"
#entry_status "Destroying GPT and MBR Data Structures"
sgdisk --zap-all /dev/"${ssd1}"
#exit_status "Destroyed GPT and MBR Data Structures in /dev/${ssd1}"
#entry_status "Destroying GPT and MBR Data Structures"
sgdisk --zap-all /dev/"${hdd1}"
#exit_status "Destroyed GPT and MBR Data Structures in /dev/${hdd1}"
#entry_status "Creating New Partition"
sgdisk --new=1:0:+1G --typecode=1:EF00 --change-name=1:"EFI system partition" /dev/"${ssd1}"
sgdisk --new=2:0:+4G --typecode=2:8200 --change-name=2:"Linux swap" /dev/"${ssd1}"
sgdisk --new=3:0:0 --typecode=3:8300 --change-name=3:"Linux filesystem" /dev/"${ssd1}"
#exit_status "Created New Partition in /dev/${ssd1}"
#entry_status "Creating New Partition"
sgdisk --new=1:0:0 --typecode=1:8300 --change-name=1:"Linux filesystem" /dev/"${hdd1}"
#exit_status "Created New Partition in /dev/${hdd1}"
#exit_status "Partitioned Disks"

# Format the partitions
#entry_status "Formatting Partitions"
root_partition="${ssd1}3"
home_partition="${hdd1}1"
swap_partition="${ssd1}2"
efi_system_partition="${ssd1}1"
#entry_status "Creating Ext4 File System"
mkfs.ext4 -F /dev/"${root_partition}"
#exit_status "Created Ext4 File System in /dev/${root_partition}"
#entry_status "Creating Ext4 File System"
mkfs.ext4 -F /dev/"${home_partition}"
#exit_status "Created Ext4 File System in /dev/${home_partition}"
#entry_status "Initializing Linux Swap"
mkswap /dev/"${swap_partition}"
#exit_status "Initialized Linux Swap in /dev/${swap_partition}"
#entry_status "Formatting EFI System Partition"
mkfs.fat -F 32 /dev/"${efi_system_partition}"
#exit_status "Formatted EFI System Partition in /dev/${efi_system_partition}"
#exit_status "Formatted Partitions"

# Mount the file systems
#entry_status "Mounting File Systems"
#entry_status "Mounting Root Volume"
mount /dev/"${root_partition}" /mnt
#exit_status "Mounted Root Volume in /mnt"
#entry_status "Creating Directory for EFI System Partition"
mkdir /mnt/boot
#exit_status "Created Directory for EFI System Partition in /mnt/boot"
#entry_status "Mounting EFI System Partition"
mount /dev/"${efi_system_partition}" /mnt/boot
#exit_status "Mounted EFI System Partition in /mnt/boot"
#entry_status "Creating Directory for Home Partition"
mkdir /mnt/home
#exit_status "Created Directory for Home Partition in /mnt/boot"
#entry_status "Mounting Home Partition"
mount /dev/"${home_partition}" /mnt/home
#exit_status "Mounted Home Partition in /mnt/home"
#entry_status "Enabling Swap Partition"
swapon /dev/"${swap_partition}"
#exit_status "Enabling Swap Partition"
#exit_status "Mounted File Systems"

#######################################
# Installation
#######################################

# Select the mirrors
#entry_status "Selecting Mirrors"
reflector --save /etc/pacman.d/mirrorlist --sort rate --verbose --fastest 10 --latest 20 --protocol https,http
#exit_status "Selected Mirrors"

# Install essential packages
#entry_status "Installing Essential Packages"
pacstrap -K /mnt base base-devel linux linux-firmware linux-zen linux-zen-headers amd-ucode exfatprogs ntfs-3g networkmanager neovim man-db man-pages texinfo
#exit_status "Installed Essential Packages"

#######################################
# Configure The System
#######################################

# Fstab
#entry_status "Generating Fstab File"
genfstab -U /mnt >> /mnt/etc/fstab
#exit_status "Generated Fstab File in /mnt/etc/fstab"

cat << EOF > /mnt/configure.sh
#!/bin/bash

# Time
#entry_status "Setting Time Zone"
ln -sf /usr/share/zoneinfo/"${time_zone}" /etc/localtime
#exit_status "Set Time Zone to ${time_zone}"
#entry_status "Generating /etc/adjtime"
hwclock --systohc
#exit_status "Generated /etc/adjtime"
#entry_status "Enabling systemd-timesyncd.service"
systemctl enable systemd-timesyncd.service
#exit_status "Enabled systemd-timesyncd.service"

# Localization
#entry_status "Uncommenting ${utf_locale}"
sed --in-place 's/#${utf_locale}/${utf_locale}/g' /etc/locale.gen
#exit_status "Uncommented ${utf_locale} in /etc/locale.gen"
#entry_status "Uncommenting ${iso_locale}"
sed --in-place 's/#${iso_locale}/${iso_locale}/g' /etc/locale.gen
#exit_status "Uncommented ${iso_locale} in /etc/locale.gen"
#entry_status "Generating Locales"
locale-gen
#exit_status "Generated Locales"
#entry_status "Setting System Locale"
echo "LANG="${language}"" >> /etc/locale.conf
#exit_status "Set System Locale in /etc/locale.conf"
#entry_status "Setting Console Keyboard Layout"
echo "KEYMAP="${console_keyboard}"" >> /etc/vconsole.conf
#exit_status "Set Console Keyboard Layout to ${console_keyboard}"

# Network configuration
#entry_status "Creating Hostname File"
echo "${hostname}" >> /etc/hostname
#exit_status "Created Hostname (${hostname}) File in /etc/hostname"
#entry_status "Enabling NetworkManager.service"
systemctl enable NetworkManager.service
#exit_status "Enabled NetworkManager.service"

# Root password
#entry_status "Setting Root Password"
printf "%s\n%s" "${root_passwd}" "${root_passwd}" | passwd
#exit_status "Set Root Password"

# Boot loader
#entry_status "Installing Boot Loader"
pacman -S --noconfirm grub efibootmgr
#exit_status "Installed Boot Loader (GRUB)"
#entry_status "Installing GRUB"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
#exit_status "Installed GRUB to /boot"
#entry_status "Generating Main Configuration File"
grub-mkconfig -o /boot/grub/grub.cfg
#exit_status "Generated Main Configuration File in /boot/grub/grub.cfg"

#######################################
# System Administration
#######################################

# Users and groups
#entry_status "Adding New User"
useradd --create-home --groups wheel "${username}"
#exit_status "Added User (${username})"
#entry_status "Setting ${username} Password"
printf "%s\n%s" "${user_passwd}" "${user_passwd}" | passwd "${username}"
#exit_status "Set ${username} Password"

# Security
#entry_status "Allowing Members of Group Wheel Sudo Access"
sed --in-place 's/# %wheel/%wheel/g' /etc/sudoers
sed --in-place 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers
#exit_status "Allowed Members of Group Wheel Sudo Access"
#entry_status "Disabling Password Prompt Timeout"
echo "Defaults passwd_timeout=0" >> /etc/sudoers
#exit_status "Disabled Password Prompt Timeout"

#######################################
# Package Management
#######################################

# pacman
#entry_status "Installing Pacman Contrib"
pacman -S --noconfirm pacman-contrib
#exit_status "Installed Pacman Contrib"
#entry_status "Enabling paccache.timer"
systemctl enable paccache.timer
#exit_status "Enabled paccache.timer"

# Repositories
#entry_status "Enabling Multilib Repository"
sed --in-place 's|#\[multilib\]|\[multilib\]|g' /etc/pacman.conf
sed --in-place 's|#Include = /etc/pacman.d/mirrorlist|Include = /etc/pacman.d/mirrorlist|g' /etc/pacman.conf
#exit_status "Enabled Multilib Repository"

# Mirrors
#entry_status "Installing Reflector"
pacman -S --noconfirm reflector
#exit_status "Installed Reflector"

# Arch Build System
#entry_status "Installing Git"
pacman -S --noconfirm git
#exit_status "Installed Git"

# Arch User Repository

Install yay

#######################################
# Graphical User Interface
#######################################

# Display drivers
#entry_status "Installing AMD Radeon Graphics Card Drivers"
pacman -S --noconfirm mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon
#exit_status "Installed AMD Radeon Graphics Card Drivers"

# Window manager
Install Hyprland

# Display manager
Install greetd
Install greetd-tuigreet
#systemctl enable greetd.service

# User directories
#entry_status "Creating User Directories"
pacman -S --noconfirm xdg-user-dirs
xdg-user-dirs-update
#exit_status "Created User Directories"

#######################################
# Multimedia
#######################################

# Sound system
#entry_status "Installing Sound Servers"
pacman -S --noconfirm pipewire lib32-pipewire pipewire-docs wireplumber pipewire-audio pipewire-alsa pipewire-pulse pipewire-jack lib32-pipewire-jack
#exit_status "Installed Sound Servers"

#######################################
# Optimization
#######################################

# Solid state drives
#entry_status "Enabling fstrim.timer"
systemctl enable fstrim.timer
#exit_status "Enabled fstrim.timer"

#######################################
# System Services
#######################################

# File index and search
#entry_status "Installing Plocate"
pacman -S --noconfirm plocate
#exit_status "Installed Plocate"

#######################################
# Appearance
#######################################

# Fonts
#entry_status "Installing Noto Fonts"
pacman -S --noconfirm noto-fonts
#exit_status "Installed Noto Fonts"

#######################################
# Console Improvements
#######################################

# Tab-completion enhancements
#entry_status "Installing Bash Completion"
pacman -S --noconfirm bash-completion
#exit_status "Installed Bash Completion"

# Aliases

# Alternative shells

# Compressed files
#entry_status "Installing Archiving and Compression Tools"
pacman -S --noconfirm 7zip tar zip unzip
#exit_status "Installed Archiving and Compression Tools"
EOF

#######################################
# Chroot
#######################################

#entry_status "Changing File Mode Bits"
chmod +x /mnt/configure.sh
#exit_status "Changed File Mode Bits"
#entry_status "Changing Root Into New System"
arch-chroot /mnt /configure.sh
#exit_status "Changed Root Into New System"

#######################################
# Post-Installation
#######################################

# Reboot
#entry_status "Removing Temporary Configuration Script"
rm /mnt/configure.sh
#exit_status "Removed Temporary Configuration Script"
#entry_status "Unmounting All Partitions"
umount -R /mnt
#exit_status "Unmounted All Partitions"
info_status "Welcome to Arch Linux!"
info_status "Restart the machine by typing "reboot""
info_status "Remember to remove the installation medium"
info_status "Login into the new system with the root account"
