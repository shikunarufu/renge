#!/bin/bash
#
# Renge (Arch Linux Installation Script)

# Log all actions
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>log.out 2>&1

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

# Virtualization check to set VM variables
if systemd-detect-virt --quiet --vm; then
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
  # Root Password
  while true
  do
    printf '%s\n' 'Note: Characters are hidden.'
    read -rs -p "Enter Root Password: " ROOT_PASSWORD1
    printf '\n'
    read -rs -p "Re-enter Root Password: " ROOT_PASSWORD2
    printf '\n'
    if [[ "$ROOT_PASSWORD1" == "$ROOT_PASSWORD2" ]]; then
      break
    else
      clear
      printf '%s\n' 'Passwords do not match!'
    fi
  done
  clear
  export ROOT_PASSWORD=$ROOT_PASSWORD1

  # Username
  while true
  do
    printf '%s\n' 'Note: Uppercase letters are automatically converted to lowercase letters.'
    read -r -p "Enter Username: " username
    if [[ "${username,,}" =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ]]; then
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

  # User Password
  while true
  do
    printf '%s\n' 'Note: Characters are hidden.'
    read -rs -p "Enter User Password: " USER_PASSWORD1
    printf '\n'
    read -rs -p "Re-enter User Password: " USER_PASSWORD2
    printf '\n'
    if [[ "$USER_PASSWORD1" == "$USER_PASSWORD2" ]]; then
      break
    else
      clear
      printf '%s\n' 'Passwords do not match!'
    fi
  done
  export USER_PASSWORD=$USER_PASSWORD1
}

# System Information
sysinfo () {
  # Hostname
  while true
  do
    read -r -p "Enter Name of Machine: " name_of_machine
    if [[ "${name_of_machine,,}" =~ ^[a-z][a-z0-9_.-]{0,62}[a-z0-9]$ ]]; then
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
pacman --sync --refresh --noconfirm --needed archlinux-keyring

# Install CachyOS keyring
pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com
pacman-key --lsign-key F3B607488DB35A47

# Install CachyOS repository packages
pacman --upgrade --noconfirm 'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-keyring-20240331-1-any.pkg.tar.zst' \
'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-mirrorlist-27-1-any.pkg.tar.zst' \

# Virtualization check to install CachyOS x86-64-v3 repository packages
if ! systemd-detect-virt --quiet --vm; then
  pacman --upgrade --noconfirm 'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-v3-mirrorlist-27-1-any.pkg.tar.zst'
fi

# Set the console keyboard layout
keymap="us"
loadkeys "${keymap}"
export KEYMAP=$keymap

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
rate-mirrors --save=/etc/pacman.d/cachyos-mirrorlist --max-jumps=0 --entry-country="${country}" --allow-root cachyos
export COUNTRY=$country

# Virtualization check to select CachyOS x86-64-v3 mirrors
if ! systemd-detect-virt --quiet --vm; then
  cp /etc/pacman.d/cachyos-mirrorlist /etc/pacman.d/cachyos-v3-mirrorlist
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

# Virtualization check to append CachyOS repositories
if ! systemd-detect-virt --quiet --vm; then
  sed --in-place '76 a [cachyos-v3]' /etc/pacman.conf
  sed --in-place '77 a Include = /etc/pacman.d/cachyos-v3-mirrorlist' /etc/pacman.conf
  sed --in-place '78 a \\' /etc/pacman.conf
  sed --in-place '79 a [cachyos-core-v3]' /etc/pacman.conf
  sed --in-place '80 a Include = /etc/pacman.d/cachyos-v3-mirrorlist' /etc/pacman.conf
  sed --in-place '81 a \\' /etc/pacman.conf
  sed --in-place '82 a [cachyos-extra-v3]' /etc/pacman.conf
  sed --in-place '83 a Include = /etc/pacman.d/cachyos-v3-mirrorlist' /etc/pacman.conf
  sed --in-place '84 a \\' /etc/pacman.conf
  sed --in-place '76 a [cachyos]' /etc/pacman.conf
  sed --in-place '77 a Include = /etc/pacman.d/cachyos-mirrorlist' /etc/pacman.conf
  sed --in-place '78 a \\' /etc/pacman.conf
else
  sed --in-place '76 a [cachyos]' /etc/pacman.conf
  sed --in-place '77 a Include = /etc/pacman.d/cachyos-mirrorlist' /etc/pacman.conf
  sed --in-place '78 a \\' /etc/pacman.conf
fi

# Refresh repositories
pacman --sync --refresh

# Parallel compilation
sed --in-place "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$thread\"/g" /etc/makepkg.conf

# Multiple cores on compression
sed --in-place "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c --threads=$thread -z -)/g" /etc/makepkg.conf

# Install essential packages
grep --extended-regexp --only-matching '^[^(#|[:space:])]*' ./renge/pkgs/install-pacstrap-pkglist.txt \
| sort --output=./renge/pkgs/install-pacstrap-pkglist.txt --unique
pacstrap -K /mnt - < ./renge/pkgs/install-pacstrap-pkglist.txt

#######################################
# Chroot Preparation
#######################################

# Time
time_zone="$(curl --fail --max-time 5 --silent https://ipapi.co/timezone)"
export TIME_ZONE=$time_zone

# Configure bootloader
root_uuid="$(blkid -s UUID -o value "$root_part")"

# Prepare configuration file for bootloader
cat << EOF > /mnt/limine.conf
timeout: 3
default_entry: Arch Linux/linux-cachyos
remember_last_entry: yes
interface_resolution: 1920x1080

/+Arch Linux
  //linux-cachyos
  protocol: linux
  path: boot():/vmlinuz-linux-cachyos
  cmdline: root=UUID=${root_uuid} rootflags=subvol=@,noatime,compress=zstd,ssd,commit=120 rw rootfstype=btrfs
  module_path: boot():/initramfs-linux-cachyos.img

  //linux-zen
  protocol: linux
  path: boot():/vmlinuz-linux-zen
  cmdline: root=UUID=${root_uuid} rootflags=subvol=@,noatime,compress=zstd,ssd,commit=120 rw rootfstype=btrfs
  module_path: boot():/initramfs-linux-zen.img
EOF

#######################################
# Configure the system
#######################################

# Generate fstab file
genfstab -U /mnt >> /mnt/etc/fstab

# Change root into new system
arch-chroot -S /mnt /bin/bash << EOF

# Set time zone
ln --force --symbolic /usr/share/zoneinfo/"$(TIME_ZONE)" /etc/localtime
hwclock --systohc

# Generate locales
locale="en_GB.UTF-8 UTF-8"
sed --in-place 's/#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/g' /etc/locale.gen
sed --in-place 's/#en_GB ISO-8859-1/en_GB ISO-8859-1/g' /etc/locale.gen
locale-gen

# Set system locale
echo "LANG=en_GB.UTF-8" > /etc/locale.conf

# Set console keyboard layout and font
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf

# Network configuration
systemctl enable NetworkManager

# Set hostname
echo "${NAME_OF_MACHINE}" > /etc/hostname

# Set root password
echo "root:${ROOT_PASSWORD}" | chpasswd

#######################################
# System administration
#######################################

# Users and groups
useradd --create-home --groups wheel --shell /bin/bash "${USERNAME}"
echo "${USERNAME}:${USER_PASSWORD}" | chpasswd

# Security
sed --in-place 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers
sed --in-place 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers
printf "%s\n" "Defaults passwd_timeout=0" >> /etc/sudoers

#######################################
# Package management
#######################################

# pacman
sed --in-place 's/#Color/Color/g' /etc/pacman.conf
sed --in-place '/Color/a ILoveCandy' /etc/pacman.conf
sed --in-place 's/CheckSpace/#CheckSpace/g' /etc/pacman.conf
sed --in-place 's/#VerbosePkgLists/VerbosePkgLists/g' /etc/pacman.conf
thread="$(nproc)"
sed --in-place "s/ParallelDownloads = 5/ParallelDownloads = $thread/g" /etc/pacman.conf
sed --in-place '/#DisableSandboxSyscalls/a DisableDownloadTimeout' /etc/pacman.conf

# Update Arch Linux keyring
pacman --sync --refresh
pacman --sync --noconfirm archlinux-keyring

# Install CachyOS keyring
pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com
pacman-key --lsign-key F3B607488DB35A47

# Repositories
sed --in-place 's|#\[multilib\]|\[multilib\]|g' /etc/pacman.conf
sed --in-place '96s|#Include = /etc/pacman.d/mirrorlist|Include = /etc/pacman.d/mirrorlist|g' /etc/pacman.conf

# Install CachyOS repository packages
pacman --upgrade --noconfirm 'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-keyring-20240331-1-any.pkg.tar.zst' \
'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-mirrorlist-27-1-any.pkg.tar.zst' \

# Virtualization check to install CachyOS x86-64-v3 repository packages
if ! systemd-detect-virt --quiet --vm; then
  pacman --upgrade --noconfirm 'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-v3-mirrorlist-27-1-any.pkg.tar.zst'
fi

# Virtualization check to append CachyOS repositories
if ! systemd-detect-virt --quiet --vm; then
  sed --in-place '76 a [cachyos-v3]' /etc/pacman.conf
  sed --in-place '77 a Include = /etc/pacman.d/cachyos-v3-mirrorlist' /etc/pacman.conf
  sed --in-place '78 a \\' /etc/pacman.conf
  sed --in-place '79 a [cachyos-core-v3]' /etc/pacman.conf
  sed --in-place '80 a Include = /etc/pacman.d/cachyos-v3-mirrorlist' /etc/pacman.conf
  sed --in-place '81 a \\' /etc/pacman.conf
  sed --in-place '82 a [cachyos-extra-v3]' /etc/pacman.conf
  sed --in-place '83 a Include = /etc/pacman.d/cachyos-v3-mirrorlist' /etc/pacman.conf
  sed --in-place '84 a \\' /etc/pacman.conf
  sed --in-place '76 a [cachyos]' /etc/pacman.conf
  sed --in-place '77 a Include = /etc/pacman.d/cachyos-mirrorlist' /etc/pacman.conf
  sed --in-place '78 a \\' /etc/pacman.conf
else
  sed --in-place '76 a [cachyos]' /etc/pacman.conf
  sed --in-place '77 a Include = /etc/pacman.d/cachyos-mirrorlist' /etc/pacman.conf
  sed --in-place '78 a \\' /etc/pacman.conf
fi

# Select CachyOS mirrors
pacman --sync --noconfirm --needed rate-mirrors
rate-mirrors --save=/etc/pacman.d/cachyos-mirrorlist --max-jumps=0 --entry-country="${COUNTRY}" --allow-root cachyos

# Virtualization check to select CachyOS x86-64-v3 mirrors
if ! systemd-detect-virt --quiet --vm; then
  cp /etc/pacman.d/cachyos-mirrorlist /etc/pacman.d/cachyos-v3-mirrorlist
fi

# Refresh repositories
pacman --sync --refresh --upgrade

# Parallel compilation
sed --in-place "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$thread\"/g" /etc/makepkg.conf

# Multiple cores on compression
sed --in-place "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c --threads=$thread -z -)/g" /etc/makepkg.conf

# Install essential packages
curl https://raw.githubusercontent.com/shikunarufu/renge/refs/heads/main/pkgs/install-pacman-pkglist.txt >> install-pacman-pkglist.txt
grep --extended-regexp --only-matching '^[^(#|[:space:])]*' install-pacman-pkglist.txt | sort --output=install-pacman-pkglist.txt --unique
pacman -S --noconfirm --needed - < install-pacman-pkglist.txt
rm --force --recursive install-pacman-pkglist.txt

# Deploy boot loader
mkdir --parents /boot/EFI/arch-limine
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
mv /limine.conf /boot/EFI/arch-limine/

#######################################
# Graphical user interface
#######################################

# Configure mangowm
runuser --user="${USERNAME}" mkdir --parents /home/"${USERNAME}"/.config/mango
cp /home/"${USERNAME}"/renge/mango/config.conf /home/"${USERNAME}"/.config/mango/config.conf

# Sound system
amixer sset Master unmute
amixer sset Speaker unmute
amixer sset Headphone unmute

# User directories
xdg-user-dirs-update

# Solid state drives
systemctl enable fstrim.timer

# Cleanup
sed --in-place 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers

# Exit chroot environment
exit
EOF

#######################################
# Post-installation
#######################################

# Unmount all partitions
umount -R /mnt

# Restart system
sec=15
while [[ ${sec} -gt 1 ]]; do
  printf "\r\e[K%s" "Restarting in $sec seconds"
  sleep 1
  ((sec--))
done
printf "\r\e[K%s\n" "Restarting in 1 second"
sleep 1
reboot
