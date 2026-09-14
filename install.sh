#!/bin/bash
#
# Renge (Arch Linux Installation Script)

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

#######################################
# Configure the installation
#######################################

# System Configuration
boot_disk=/dev/sdc # SSD/NVMe
root_disk=/dev/sdc # SSD/NVMe
var_disk=/dev/sda  # HDD
home_disk=/dev/sda # HDD
data_disk=/dev/sdb # SSD/NVMe

# Check for virtualization
if systemd-detect-virt --quiet --vm; then
  # Set variables for virtualization
  boot_disk=/dev/vda
  root_disk=/dev/vda
  var_disk=/dev/vdb
  home_disk=/dev/vdb
  data_disk=/dev/vdc
fi

# Export variables
export BOOT_DISK=$boot_disk

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
  clear
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
    '4. Maximum character length is 63.'
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
keymap="us"
export KEYMAP=$keymap
loadkeys "${keymap}"

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
sgdisk --zap-all "$root_disk"
sgdisk --zap-all "$home_disk"
sgdisk --zap-all "$data_disk"

# Set sector alignment multiple to 2048 and clear all partition data
sgdisk --set-alignment=2048 --clear "$root_disk"
sgdisk --set-alignment=2048 --clear "$home_disk"
sgdisk --set-alignment=2048 --clear "$data_disk"

#######################################
# Partition the disks
#######################################

# Partition 1: UEFI Boot
sgdisk --new=1::+4096MiB --typecode=1:ef00 --change-name=1:'boot' "$boot_disk"

# Partition 2: Root
sgdisk --new=2::-0 --typecode=2:8300 --change-name=2:'root' "$root_disk"

# Partition 3: Var
sgdisk --new=1::+12G --typecode=1:8300 --change-name=1:'var' "$var_disk"

# Partition 4: Home
sgdisk --new=2::-0 --typecode=2:8300 --change-name=2:'home' "$home_disk"

# Partition 5: Data
sgdisk --new=1::-0 --typecode=1:8300 --change-name=1:'data' "$data_disk"

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
boot_part=$(nvme_check "$boot_disk" 1)
root_part=$(nvme_check "$root_disk" 2)
var_part=$(nvme_check "$var_disk" 1)
home_part=$(nvme_check "$home_disk" 2)
data_part=$(nvme_check "$data_disk" 1)

mkfs.fat -F 32 -n "boot" "${boot_part}"
mkfs.btrfs --force --label "root" "${root_part}"
mkfs.btrfs --force --label "var" "${var_part}"
mkfs.btrfs --force --label "home" "${home_part}"
mkfs.btrfs --force --label "data" "${data_part}"

#######################################
# Create the subvolumes
#######################################

mount -t btrfs "${root_part}" /mnt
btrfs subvolume create /mnt/@
# Set @ as default subvolume so genfstab records subvolid=256 (not 5)
btrfs subvolume set-default /mnt/@
umount /mnt

mount -t btrfs "${var_part}" /mnt
btrfs subvolume create /mnt/@var
umount /mnt

mount -t btrfs "${home_part}" /mnt
btrfs subvolume create /mnt/@home
umount /mnt

mount -t btrfs "${data_part}" /mnt
btrfs subvolume create /mnt/@data
umount /mnt

#######################################
# Mount the file systems
#######################################

# Mount @ subvolume
mount --options noatime,compress=zstd,ssd,commit=120,subvol=@ "${root_part}" /mnt

# Create directories for subvolumes
mkdir --parents /mnt/var
mkdir --parents /mnt/home
mkdir --parents /mnt/data
mkdir --parents /mnt/boot

# Mount all subvolumes
mount --options noatime,compress=zstd,commit=120,subvol=@var "${var_part}" /mnt/var
mount --options noatime,compress=zstd,commit=120,subvol=@home "${home_part}" /mnt/home
mount --options noatime,compress=zstd,ssd,commit=120,subvol=@data "${data_part}" /mnt/data
boot_uuid="$(blkid -s UUID -o value "$boot_part")"
mount --uuid "${boot_uuid}" /mnt/boot/

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

# Refresh repositories
pacman --sync --refresh

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

# Generate fstab file
genfstab -U /mnt >> /mnt/etc/fstab

# Configure Limine
limine_config () {
  root_uuid="$(blkid -s UUID -o value "$root_part")"
  cat << 'EOF' > /boot/EFI/arch-limine/limine.conf
  timeout: 5

  /Arch Linux
      protocol: linux
      path: boot():/vmlinuz-linux
      cmdline: root=UUID=${root_uuid} rw
      module_path: boot():/initramfs-linux.img
  EOF
}
export -f limine_config

# Change root into new system
arch-chroot -S /mnt /bin/bash <<EOF

# Set time zone
time_zone="$(curl --fail --max-time 5 --silent https://ipapi.co/timezone)"
ln --force --symbolic /usr/share/zoneinfo/"${time_zone}" /etc/localtime
hwclock --systohc

# Generate locales
locale="en_GB.UTF-8 UTF-8"
sed --in-place 's/^#${locale}/${locale}/' /etc/locale.gen
locale-gen

# Set system locale
echo "LANG=${locale}" > /etc/locale.conf

# Set console keyboard layout and font
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf

# Network configuration
systemctl enable NetworkManager

# Set hostname
echo "${NAME_OF_MACHINE}" > /etc/hostname

# Set root password
echo "${PASSWORD}" | chpasswd

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

# Refresh repositories
pacman --sync --refresh

# Parallel compilation
core=$(grep --count ^processor /proc/cpuinfo)
sed --in-place "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$core\"/g" /etc/makepkg.conf

# Install boot loader
pacman --sync --noconfirm --needed limine efibootmgr

# Deploy boot loader
mkdir -p /boot/EFI/arch-limine
cp /usr/share/limine/BOOTX64.EFI /boot/EFI/arch-limine/

# Add entry for bootloader
efibootmgr \
--create \
--disk "${BOOT_DISK}" \
--part 1 \
--label "Arch Linux Limine Boot Loader" \
--loader '\EFI\arch-limine\BOOTX64.EFI' \
--unicode

# Configure bootloader
limine_config

EOF
