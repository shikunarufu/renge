#!/bin/bash
#
# Shiku's Arch Linux Installation Script

# This script automates the Arch Linux installation process
# as per the official installation guide.

# This script assumes you have already booted from an installation medium
# made from an official installation image.

# This script assumes a working internet connection is available.

# It is recommended to install Arch Linux 
# manually using the official installation guide.

#######################################
# Preparation
#######################################

# Configuration
consolekeyboard="us"
consolefont="Lat2-Terminus16"
ssd1="sda"
hdd1="sda"

timezone="Asia/Manila"
utflocale="en_GB.UTF-8 UTF-8"
isolocale="en_GB ISO-8859-1"
lang="en_GB.UTF-8"
hostname="Renge"
rpasswd="nyanpasu"
username="Shiku"
upasswd="narufu"

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
entry_status "Clearing Terminal Screen"
clear
exit_status "Cleared Terminal Screen"

#######################################
# Pre-Installation
#######################################

# Set the console keyboard layout and font
entry_status "Setting Console Keyboard Layout"
loadkeys "${consolekeyboard}"
exit_status "Set Console Keyboard Layout to ${consolekeyboard}"
entry_status "Setting Console Font"
setfont "${consolefont}"
exit_status "Set Console Font to ${consolefont}"

# Verify the boot mode
entry_status "Verifying Boot Mode"
bootmode=$(< /sys/firmware/efi/fw_platform_size)
if [[ "${bootmode}" == "64" ]]; then
  info_status "System is booted in UEFI mode and has a 64-bit x64 UEFI"
elif [[ "${bootmode}" == "32" ]]; then
  info_status "System is booted in UEFI mode and has a 32-bit IA32 UEFI"
else
  info_status "System may be booted in BIOS (or CSM) mode"
  info_status "Refer to your motherboard's manual"
fi
exit_status "Verified Boot Mode"

# Connect to the internet
entry_status "Connecting to Internet"
ping -c 5 archlinux.org > /dev/null 2>&1
exit_status "Connected to Internet"

# Update the system clock
entry_status "Updating System Clock"
timedatectl set-ntp true
exit_status "Updated System Clock"

# Partition the disks
entry_status "Partitioning Disks"
entry_status "Destroying GPT and MBR Data Structures"
sgdisk --zap-all /dev/"${ssd1}" > /dev/null 2>&1
exit_status "Destroyed GPT and MBR Data Structures in /dev/${ssd1}"
entry_status "Destroying GPT and MBR Data Structures"
sgdisk --zap-all /dev/"${hdd1}" > /dev/null 2>&1
exit_status "Destroyed GPT and MBR Data Structures in /dev/${hdd1}"
entry_status "Erasing All Available Signatures"
wipefs --all --force /dev/"${ssd1}"
exit_status "Erased All Available Signatures in /dev/${ssd1}"
entry_status "Erasing All Available Signatures"
wipefs --all --force /dev/"${hdd1}"
exit_status "Erased All Available Signatures in /dev/${hdd1}"
entry_status "Rereading Partition Table"
partprobe /dev/"${ssd1}"
exit_status "Reread Partition Table in /dev/${ssd1}"
entry_status "Rereading Partition Table"
partprobe /dev/"${hdd1}"
exit_status "Reread Partition Table in /dev/${hdd1}"
entry_status "Creating New Partition"
sgdisk --new=1:0:+1G --new=2:0:+4G --new=3:0:0 /dev/"${ssd1}" > /dev/null 2>&1
exit_status "Created New Partition in /dev/${ssd1}"
entry_status "Creating New Partition"
sgdisk --new=1:0:0 /dev/"${hdd1}" > /dev/null 2>&1
exit_status "Created New Partition in /dev/${hdd1}"
entry_status "Changing Partition Type Code"
sgdisk --typecode=1:EF00 --typecode=2:8200 --typecode=3:8300 /dev/"${ssd1}" > /dev/null 2>&1
exit_status "Changed Partition Type Code in /dev/${ssd1}"
entry_status "Changing Partition Type Code"
sgdisk --typecode=1:8300  /dev/"${hdd1}" > /dev/null 2>&1
exit_status "Changed Partition Type Code in /dev/${hdd1}"
entry_status "Changing GPT Name of Partition"
sgdisk --change-name=1:"EFI system partition" --change-name=2:"Linux swap" --change-name=3:"Linux filesystem" /dev/"${ssd1}" > /dev/null 2>&1
exit_status "Changed GPT Name of Partition in /dev/${ssd1}"
entry_status "Changing GPT Name of Partition"
sgdisk --change-name=1:"Linux filesystem" /dev/"${hdd1}" > /dev/null 2>&1
exit_status "Changed GPT Name of Partition in /dev/${hdd1}"
entry_status "Rereading Partition Table"
partprobe /dev/"${ssd1}" > /dev/null 2>&1
exit_status "Reread Partition Table in /dev/${ssd1}"
entry_status "Rereading Partition Table"
partprobe /dev/"${hdd1}" > /dev/null 2>&1
exit_status "Reread Partition Table in /dev/${hdd1}"
exit_status "Partitioned Disks"

# Format the partitions
entry_status "Formatting Partitions"
root_partition="${ssd1}3"
home_partition="${hdd1}1"
swap_partition="${ssd1}2"
efi_system_partition="${ssd1}1"
entry_status "Creating Ext4 File System"
mkfs.ext4 -F /dev/"${root_partition}" > /dev/null 2>&1
exit_status "Created Ext4 File System in /dev/${root_partition}"
entry_status "Creating Ext4 File System"
mkfs.ext4 -F /dev/"${home_partition}" > /dev/null 2>&1
exit_status "Created Ext4 File System in /dev/${home_partition}"
entry_status "Initializing Linux Swap"
mkswap /dev/"${swap_partition}" > /dev/null 2>&1
exit_status "Initialized Linux Swap in /dev/${swap_partition}"
entry_status "Formatting EFI System Partition"
mkfs.fat -F 32 /dev/"${efi_system_partition}" > /dev/null 2>&1
exit_status "Formatted EFI System Partition in /dev/${efi_system_partition}"
exit_status "Formatted Partitions"

# Mount the file systems
entry_status "Mounting File Systems"
entry_status "Mounting Root Volume"
mount /dev/"${root_partition}" /mnt > /dev/null 2>&1
exit_status "Mounted Root Volume in /mnt"
entry_status "Creating Directory for EFI System Partition"
mkdir /mnt/boot
exit_status "Created Directory for EFI System Partition in /mnt/boot"
entry_status "Mounting EFI System Partition"
mount /dev/"${efi_system_partition}" /mnt/boot > /dev/null 2>&1
exit_status "Mounted EFI System Partition in /mnt/boot"
entry_status "Creating Directory for Home Partition"
mkdir /mnt/home
exit_status "Created Directory for Home Partition in /mnt/boot"
entry_status "Mounting Home Partition"
mount /dev/"${home_partition}" /mnt/home
exit_status "Mounted Home Partition in /mnt/home"
entry_status "Enabling Swap Partition"
swapon /dev/"${swap_partition}" > /dev/null 2>&1
exit_status "Enabling Swap Partition"
exit_status "Mounted File Systems"

#######################################
# Installation
#######################################

# Select the mirrors
entry_status "Selecting Mirrors"
reflector --save /etc/pacman.d/mirrorlist --sort rate --verbose -f 20 -l 200 -p https,http > /dev/null 2>&1
exit_status "Selected Mirrors"

# Install essential packages
entry_status "Installing Essential Packages"
pacstrap -K /mnt base base-devel linux linux-firmware linux-zen linux-zen-headers amd-ucode exfatprogs ntfs-3g  networkmanager neovim man-db man-pages texinfo > /dev/null 2>&1
exit_status "Installed Essential Packages"

#######################################
# Configure The System
#######################################

cat << EOF > /mnt/configure.sh
#!/bin/bash

# Fstab
entry_status "Generating Fstab File"
genfstab -U /mnt >> /mnt/etc/fstab
exit_status "Generated Fstab File in /mnt/etc/fstab"

# Time
entry_status "Setting Time Zone"
ln -sf /usr/share/zoneinfo/"${timezone}" /etc/localtime
exit_status "Set Time Zone to ${timezone}"
entry_status "Generating /etc/adjtime"
hwclock --systohc
exit_status "Generated /etc/adjtime"

# Localization
entry_status "Uncommenting ${utflocale}"
sed --in-place 's/"#${utflocale}"/"${utflocale}"/' /etc/locale.gen
exit_status "Uncommented ${utflocale} in /etc/locale.gen"
entry_status "Uncommenting ${isolocale}"
sed --in-place 's/"#${isolocale}"/"${isolocale}"/' /etc/locale.gen
exit_status "Uncommented ${isolocale} in /etc/locale.gen"
entry_status "Generating Locales"
locale-gen > /dev/null 2>&1
exit_status "Generated Locales"
entry_status "Setting System Locale"
echo "LANG="${lang}"" >> /etc/locale.conf
exit_status "Set System Locale in /etc/locale.conf"
entry_status "Setting Console Keyboard Layout"
echo "KEYMAP="${consolekeyboard}"" >> /etc/vconsole.conf
exit_status "Set Console Keyboard Layout to ${consolekeyboard}"

# Network configuration
entry_status "Creating Hostname File"
echo "${hostname}" >> /etc/hostname
exit_status "Created Hostname (${hostname}) File in /etc/hostname"
entry_status "Enabling NetworkManager.service"
systemctl enable NetworkManager.service
exit_status "Enabled NetworkManager.service"

# Root password
entry_status "Setting Root Password"
printf "%s\n%s" "${rpasswd}" "${rpasswd}" | passwd > /dev/null 2>&1
exit_status "Set Root Password"

# Boot loader
entry_status "Installing Boot Loader"
pacman -S --noconfirm grub efibootmgr > /dev/null 2>&1
exit_status "Installed Boot Loader (GRUB)"
entry_status "Installing GRUB"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB > /dev/null 2>&1
exit_status "Installed GRUB to /boot"
entry_status "Generating Main Configuration File"
grub-mkconfig -o /boot/grub/grub.cfg > /dev/null 2>&1
exit_status "Generated Main Configuration File in /boot/grub/grub.cfg"

#######################################
# System Administration
#######################################

# Users and groups
entry_status "Adding New User"
useradd -m -G wheel "${username}"
exit_status "Added User (${username})"
entry_status "Setting ${username} Password"
printf "%s\n%s" "${upasswd}" "${upasswd}" | passwd "${username}" > /dev/null 2>&1
exit_status "Set ${username} Password"

# Security
entry_status "Allowing Members of Group Wheel Sudo Access"
sed --in-place 's/# %wheel/%wheel/g' /etc/sudoers
sed --in-place 's/%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers
exit_status "Allowed Members of Group Wheel Sudo Access"
entry_status "Disabling Password Prompt Timeout"
echo "Defaults passwd_timeout=0" >> /etc/sudoers
exit_status "Disabled Password Prompt Timeout"

Install bash-completion

#######################################
# Package Management
#######################################

# Pacman
entry_status "Enabling paccache.timer"
systemctl enable paccache.timer
exit_status "Enabled paccache.timer"

# Repositories
sed --in-place 's/"#[multilib]"/"[multilib]"/' /etc/pacman.conf
sed --in-place 's|"#Include = /etc/pacman.d/mirrorlist"/"Include = /etc/pacman.d/mirrorlist"/' /etc/pacman.conf
EOF

chmod +x /mnt/configure.sh
arch-chroot /mnt /configure.sh
