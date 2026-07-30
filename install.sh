#!/bin/bash
#
# Renge (Arch Linux Installation Script)

#######################################
# Configure the installation
#######################################

# System Configuration
BOOT_DISK=/dev/sdc # SSD/NVMe
ROOT_DISK=/dev/sdc # SSD/NVMe
VAR_DISK=/dev/sda  # HDD
HOME_DISK=/dev/sda # HDD
DATA_DISK=/dev/sdb # SSD/NVMe

# Check for virtualization
if systemd-detect-virt --quiet --vm; then
  # Set variables for virtualization
  BOOT_DISK=/dev/vda
  ROOT_DISK=/dev/vda
  VAR_DISK=/dev/vdb
  HOME_DISK=/dev/vdb
  DATA_DISK=/dev/vdc
fi

# User Information
userinfo () {
  # Username
  while true
  do
    printf '%s\n' 'Note: Uppercase letters are automatically converted to lowercase letters.'
    read -r -p "Enter Username: " username
    if [[ "${username,,}" =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ]]
    then
      break
    fi
    clear
    printf '%s\n' \
    'Invalid username!' \
    'Check the following:' \
    '1. Must start with a letter or an underscore.' \
    '2. Must NOT contain spaces and special characters.' \
    '3. Maximum character length is 32.'
  done
  export USERNAME=$username

  # Password
  while true
  do
    printf '%s\n' 'Note: Characters are hidden.'
    read -rs -p "Enter Password: " PASSWORD1
    printf '%s\n'
    read -rs -p "Re-enter Password: " PASSWORD2
    printf '%s\n'
    if [[ "$PASSWORD1" == "$PASSWORD2" ]]; then
      break
    else
      clear
      printf '%s\n' 'Passwords do not match!'
    fi
  done
  export PASSWORD=$PASSWORD1
}

# System Information
sysinfo () {
  # Hostname
  while true
  do
    read -r -p "Enter Name of Machine: " name_of_machine
    # hostname regex (!!couldn't find spec for computer name!!)
    if [[ "${name_of_machine,,}" =~ ^[a-z][a-z0-9_.-]{0,62}[a-z0-9]$ ]]
    then
      break
    fi
    clear
    printf '%s\n' \
    'Invalid Hostname!' \
    'Check the following:' \
    '1. Must start with a letter.' \
    '2. Must NOT contain spaces and special characters (except: underscore, dot, and hyphen).' \
    '3. Must end with a letter or a number.' \
    '4. Maximum character length is 64.'
  done
  export NAME_OF_MACHINE=$name_of_machine
}

# Start the functions
clear
userinfo
clear
sysinfo
clear

#######################################
# Pre-installation
#######################################

# Verify the internet connection
ping -c 1 ping.archlinux.org

# Update Arch Linux keyring
pacman --sync --refresh
pacman --sync --noconfirm archlinux-keyring

# Check for virtualization
if ! systemd-detect-virt --quiet --vm; then
  # Install CachyOS keyring
  pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com
  pacman-key --lsign-key F3B607488DB35A47

  # Install CachyOS repositories
  pacman --upgrade --noconfirm 'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-keyring-20240331-1-any.pkg.tar.zst' \
  'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-v3-mirrorlist-27-1-any.pkg.tar.zst'
  pacman --sync --refresh
fi

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

# Check for virtualization
if ! systemd-detect-virt --quiet --vm; then
  rate-mirrors --save=/etc/pacman.d/cachyos-mirrorlist --max-jumps=0 --entry-country="${country}" --allow-root cachyos
fi

#######################################
# Prepare the disks
#######################################

# Install prerequisite packages
pacman --sync --noconfirm gptfdisk btrfs-progs glibc

# Unmount all disks
umount --all-targets --recursive /mnt || true

# Destroy GPT and MBR data structure on all disks
sgdisk --zap-all "$ROOT_DISK"
sgdisk --zap-all "$HOME_DISK"
sgdisk --zap-all "$DATA_DISK"

# Set sector alignment multiple to 2048 and clear all partition data
sgdisk --set-alignment=2048 --clear "$ROOT_DISK"
sgdisk --set-alignment=2048 --clear "$HOME_DISK"
sgdisk --set-alignment=2048 --clear "$DATA_DISK"

#######################################
# Partition the disks
#######################################

# Partition 1: UEFI Boot
sgdisk --new=1::+4096MiB --typecode=1:ef00 --change-name=1:'boot' "$BOOT_DISK"

# Partition 2: Root
sgdisk --new=2::-0 --typecode=2:8300 --change-name=2:'root' "$ROOT_DISK"

# Partition 3: Var
sgdisk --new=1::+12G --typecode=1:8300 --change-name=1:'var' "$VAR_DISK"

# Partition 4: Home
sgdisk --new=2::-0 --typecode=2:8300 --change-name=2:'home' "$HOME_DISK"

# Partition 5: Data
sgdisk --new=1::-0 --typecode=1:8300 --change-name=1:'data' "$DATA_DISK"

#######################################
# Format the partitions
#######################################

# Check if drive is NVMe
nvme_check() {
  if [[ "$1" =~ nvme ]]; then
    echo "${1}p${2}"
      else
    echo "${1}${2}"
  fi
}

# Set variables for format
BOOT_PART=$(nvme_check "$BOOT_DISK" 1)
ROOT_PART=$(nvme_check "$ROOT_DISK" 2)
VAR_PART=$(nvme_check "$VAR_DISK" 1)
HOME_PART=$(nvme_check "$HOME_DISK" 2)
DATA_PART=$(nvme_check "$DATA_DISK" 1)

mkfs.fat -F 32 -n "boot" "${BOOT_PART}"
mkfs.btrfs --force --label "root" "${ROOT_PART}"
mkfs.btrfs --force --label "var" "${VAR_PART}"
mkfs.btrfs --force --label "home" "${HOME_PART}"
mkfs.btrfs --force --label "data" "${DATA_PART}"

#######################################
# Create the subvolumes
#######################################

mount -t btrfs "${ROOT_PART}" /mnt
btrfs subvolume create /mnt/@
# Set @ as default subvolume so genfstab records subvolid=256 (not 5)
btrfs subvolume set-default /mnt/@
umount /mnt

mount -t btrfs "${VAR_PART}" /mnt
btrfs subvolume create /mnt/@var
umount /mnt

mount -t btrfs "${HOME_PART}" /mnt
btrfs subvolume create /mnt/@home
umount /mnt

mount -t btrfs "${DATA_PART}" /mnt
btrfs subvolume create /mnt/@data
umount /mnt

#######################################
# Mount the file systems
#######################################

# Mount @ subvolume
mount --options noatime,compress=zstd,ssd,commit=120,subvol=@ "${ROOT_PART}" /mnt

# Create directories for subvolumes
mkdir --parents /mnt/var
mkdir --parents /mnt/home
mkdir --parents /mnt/data
mkdir --parents /mnt/boot

# Mount all subvolumes
mount --options noatime,compress=zstd,commit=120,subvol=@var "${VAR_PART}" /mnt/var
mount --options noatime,compress=zstd,commit=120,subvol=@home "${HOME_PART}" /mnt/home
mount --options noatime,compress=zstd,ssd,commit=120,subvol=@data "${DATA_PART}" /mnt/data
BOOT_UUID="$(blkid -s UUID -o value "$BOOT_PART")"
mount --uuid "${BOOT_UUID}" /mnt/boot/

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

# Check for virtualization
if ! systemd-detect-virt --quiet --vm; then
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
fi

# Parallel compilation
core=$(grep --count ^processor /proc/cpuinfo)
sed --in-place "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$core\"/g" /etc/makepkg.conf

# Install essential packages
grep --extended-regexp --only-matching '^[^(#|[:space:])]*' ./renge/pkgs/install-pacstrap-pkglist.txt \
  | sort --output=./renge/pkgs/install-pacstrap-pkglist.txt --unique
pacstrap -K /mnt - < ./renge/pkgs/install-pacstrap-pkglist.txt

#######################################
# Configure the system
#######################################

# Fstab
genfstab -U /mnt >> /mnt/etc/fstab
