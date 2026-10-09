#!/bin/bash
#
# Renge (Arch Linux Installation Script)

# Errors will cause the script to immediately fail
set -euo pipefail

# Log all command and still output to console
# exec 3>&1 4>&2
# trap 'exec 2>&4 1>&3' 0 1 2 3
# exec > >(tee -a log_renge.txt >&3) 2>&1

# Make sure relative paths are to be found
cd "$(dirname "${BASH_SOURCE[0]}")"

#######################################
# Configure the installation
#######################################

# Disk Configuration
boot_disk=/dev/sdc # SSD/NVMe
root_disk=/dev/sdc # SSD/NVMe
var_disk=/dev/sda  # HDD
home_disk=/dev/sda # HDD
data_disk=/dev/sdb # SSD/NVMe

#######################################
# Helper Functions
#######################################

# Check virtualization
check_vm () {
  systemd-detect-virt --quiet --vm
}

# Check CPU compatibility
check_cpu_v3() {
  local cpu
  cpu="$(/lib/ld-linux-x86-64.so.2 --help 2>/dev/null || true)"
  [[ "${cpu}" == *'x86-64-v3 (supported, searched)'* ]]
}

# Read package names
read_pkglist () {
  grep --extended-regexp --only-matching '^[^(#|[:space:])]*' "$1" || true
}

# Print partition path for disk and partition number
part_path () {
  if [[ "$1" =~ [0-9]$ ]]; then
    printf '%s\n' "${1}p${2}"
  else
    printf '%s\n' "${1}${2}"
  fi
}

# Configure pacman.conf
configure_pacman () {
  local conf=$1
  local threads
  threads="$(nproc)"
 
  sed --in-place \
    --expression='s/^#Color/Color/' \
    --expression='s/^CheckSpace/#CheckSpace/' \
    --expression='s/^#VerbosePkgLists/VerbosePkgLists/' \
    --expression="s/^#\\?ParallelDownloads = .*/ParallelDownloads = ${threads}/" \
    --expression='/^#\[multilib\]/,/^#Include/ s/^#//' \
    "${config}"
 
  if ! grep --quiet '^ILoveCandy' "${conf}"; then
    sed --in-place '/^Color/a ILoveCandy' "${conf}"
  fi
  if ! grep --quiet '^DisableDownloadTimeout' "${conf}"; then
    sed --in-place '/^#DisableSandboxSyscalls/a DisableDownloadTimeout' "${conf}"
  fi
}

# Add CachyOS v3 repositories
add_cachyos_v3 () {
  local conf=$1
  local block tmp
  block='[cachyos-v3]\nInclude = /etc/pacman.d/cachyos-v3-mirrorlist\n\n'
  block+='[cachyos-core-v3]\nInclude = /etc/pacman.d/cachyos-v3-mirrorlist\n\n'
  block+='[cachyos-extra-v3]\nInclude = /etc/pacman.d/cachyos-v3-mirrorlist\n\n'
 
  if grep --quiet '^\[cachyos-v3\]' "${conf}"; then
    return 0
  fi
  tmp="$(mktemp)"
  awk -v block="${block}" \
    '/^\[core\]/ && !done { print block; done = 1 } { print }' \
    "${conf}" > "${tmp}"
  cat "${tmp}" > "${conf}"
  rm --force "${tmp}"
}

# Install CachyOS keyring and mirrorlist packages
install_cachyos_v3 () {
  pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com
  pacman-key --lsign-key F3B607488DB35A47
  pacman --upgrade --noconfirm \
    'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-keyring-20240331-1-any.pkg.tar.zst' \
    'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-mirrorlist-27-1-any.pkg.tar.zst' \
    'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-v3-mirrorlist-27-1-any.pkg.tar.zst' \
    'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-v4-mirrorlist-27-1-any.pkg.tar.zst'
}

#######################################
# Installation Checks
#######################################

# Check virtualization to set VM variables
if check_vm; then
  boot_disk=/dev/vda
  root_disk=/dev/vda
  var_disk=/dev/vdb
  home_disk=/dev/vdb
  data_disk=/dev/vdc
fi

# Check CPU to set CachyOS variables
use_cachyos=0
if ! check_vm && check_cpu_v3; then
  use_cachyos=1
fi
 
if (( use_cachyos )); then
  kernel='linux-cachyos'
else
  kernel='linux-zen'
fi
 
mapfile -t disks < <(
  printf '%s\n' "${boot_disk}" "${root_disk}" "${var_disk}" \
    "${home_disk}" "${data_disk}" | sort --unique
)

# Check configuration files are present
for file in ./renge/pkgs/install-pacstrap-pkglist.txt \
            ./renge/pkgs/install-pacman-pkglist.txt; do
  if [[ ! -f "${file}" ]]; then
    printf '%s\n' "Missing file: ${file}" >&2
    exit 1
  fi
done

#######################################
# User and System Information
#######################################

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
  ROOT_PASSWORD=$ROOT_PASSWORD1

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
  USERNAME=${username,,}

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
  USER_PASSWORD=$USER_PASSWORD1
}

# System Information
sysinfo () {
  # Hostname
  while true
  do
    read -r -p "Enter Name of Machine: " name_of_machine
    if [[ "${name_of_machine,,}" =~ ^[a-z]([a-z0-9_.-]{0,61}[a-z0-9])?$ ]]; then
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
  NAME_OF_MACHINE=$name_of_machine
}

# Start the functions
clear
userinfo
clear
sysinfo
clear

# Installation confirmation
lsblk --output NAME,SIZE,MODEL,TYPE "${disks[@]}"
printf '%s\n' '' 'ALL DATA on these disks will be erased:' "${disks[@]}"
read -r -p "Type ERASE to continue: " answer
if [[ "${answer}" != 'ERASE' ]]; then
  printf '%s\n' 'Aborted.' >&2
  exit 1
fi
clear

#######################################
# Pre-installation
#######################################

# Check Secure Boot

# Verify the internet connection
ping -c 1 ping.archlinux.org

# Update Arch Linux keyring
pacman --sync --refresh --noconfirm --needed archlinux-keyring

# Install CachyOS keyring and mirrorlist packages
if (( use_cachyos )); then
  install_cachyos_v3
fi

# Select the mirrors
pacman --sync --noconfirm --needed rate-mirrors
country="$(curl --fail --silent --max-time 5 --ipv4 ifconfig.io/country_code || true)"
country_args=()
if [[ -n "${country}" ]]; then
  country_args=(--entry-country="${country}")
fi
rate-mirrors --save=/etc/pacman.d/mirrorlist --max-jumps=0 \
  "${country_args[@]}" --allow-root arch \
  || printf '%s\n' 'Warning: mirror ranking failed; keeping current mirrorlist.' >&2

# Add CachyOS v3 repositories
if (( use_cachyos )); then
  add_cachyos_v3 /etc/pacman.conf
  rate-mirrors --save=/etc/pacman.d/cachyos-v3-mirrorlist --max-jumps=0 \
    "${country_args[@]}" --allow-root cachyos \
    || printf '%s\n' 'Warning: CachyOS mirror ranking failed.' >&2
fi

# Refresh repositories
pacman --sync --refresh

# Set the console keyboard layout
keymap="us"
loadkeys "${keymap}"
KEYMAP=$keymap

# Set the console font
pacman --sync --noconfirm --needed pacman-contrib terminus-font
setfont Lat2-Terminus16

# Verify the boot mode
if [[ ! -f /sys/firmware/efi/fw_platform_size ]]; then
  printf '%s\n' 'Not booted in UEFI mode.' >&2
  exit 1
fi

# Update the system clock
timedatectl set-ntp true

#######################################
# Prepare the disks
#######################################

# Install prerequisite packages
pacman --sync --noconfirm gptfdisk btrfs-progs

# Unmount all disks
umount --all-targets --recursive /mnt

# Destroy old signatures, GPT and MBR data structure on all disks
for disk in "${disks[@]}"; do
  wipefs --all --force "${disk}"
  sgdisk --zap-all "${disk}"
done

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

# Confirm the new partitions
partprobe
udevadm settle

#######################################
# Format the partitions
#######################################

boot_part=$(part_path "$boot_disk" 1)
root_part=$(part_path "$root_disk" 2)
var_part=$(part_path "$var_disk" 1)
home_part=$(part_path "$home_disk" 2)
data_part=$(part_path "$data_disk" 1)

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
mount "${boot_part}" /mnt/boot

#######################################
# Installation
#######################################

# Configure pacman
configure_pacman /etc/pacman.conf

# Refresh repositories
pacman --sync --refresh

# Install essential packages
{ read_pkglist ./renge/pkgs/install-pacstrap-pkglist.txt; \
  printf '%s\n' "${kernel}" "${kernel}-headers"; } \
  | sort --unique \
  | pacstrap -K /mnt -

#######################################
# Chroot Preparation
#######################################

# Time
time_zone="$(curl --fail --max-time 5 --silent https://ipapi.co/timezone || true)"
if [[ -z "${time_zone}" || ! -f "/usr/share/zoneinfo/${time_zone}" ]]; then
  time_zone="Asia/Manila"
fi

# Configure bootloader
root_uuid="$(blkid -s UUID -o value "$root_part")"

# Prepare configuration file for bootloader
root_uuid="$(blkid -s UUID -o value "$root_part")"
mkdir --parents /mnt/boot/EFI/arch-limine
cat << EOF > /mnt/boot/EFI/arch-limine/limine.conf
timeout: 3
default_entry: Arch Linux/${kernel}
remember_last_entry: yes
interface_resolution: 1920x1080
/+Arch Linux
  //${kernel}
  protocol: linux
  path: boot():/vmlinuz-${kernel}
  cmdline: root=UUID=${root_uuid} rootflags=subvol=@,noatime,compress=zstd,ssd,commit=120 rw rootfstype=btrfs
  module_path: boot():/initramfs-${kernel}.img
EOF

# Copy config files
cp --recursive ./renge /mnt

#######################################
# Configure the system
#######################################

# Generate fstab file
genfstab -U /mnt >> /mnt/etc/fstab

# Create chroot script
{
  declare -f configure_pacman add_cachyos_v3 install_cachyos_v3 read_pkglist
  cat << 'CHROOT_EOF'

# Errors will cause the script to immediately fail
set -euo pipefail
 
# Build and install AUR package
install_aur() {
  local pkg=$1
  runuser --login "${USERNAME}" --command \
    "git clone https://aur.archlinux.org/${pkg}.git \"\$HOME/aur/${pkg}\" \
    && cd \"\$HOME/aur/${pkg}\" \
    && makepkg --syncdeps --install --noconfirm"
}

# Set time zone
ln --force --symbolic /usr/share/zoneinfo/"${TIME_ZONE}" /etc/localtime
hwclock --systohc
systemctl enable systemd-timesyncd

# Generate locales
sed --in-place 's/#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/g' /etc/locale.gen
sed --in-place 's/#en_GB ISO-8859-1/en_GB ISO-8859-1/g' /etc/locale.gen
locale-gen

# Set system locale
echo "LANG=en_GB.UTF-8" > /etc/locale.conf

# Set console keyboard layout
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf

# Network configuration
systemctl enable NetworkManager

# Set hostname
echo "${NAME_OF_MACHINE}" > /etc/hostname

#######################################
# System administration
#######################################

# Users and groups
useradd --create-home --groups wheel --shell /bin/bash "${USERNAME}"

# Setup NOPASSWD rule for AUR builds
trap 'rm --force /etc/sudoers.d/99-installer-nopasswd' EXIT
printf '%s\n' '%wheel ALL=(ALL:ALL) ALL' 'Defaults passwd_timeout=0' \
  > /etc/sudoers.d/10-wheel
printf '%s\n' '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' \
  > /etc/sudoers.d/99-installer-nopasswd
chmod 0440 /etc/sudoers.d/10-wheel /etc/sudoers.d/99-installer-nopasswd
visudo --check

#######################################
# Package management
#######################################

# pacman
configure_pacman /etc/pacman.conf

# Update Arch Linux keyring
pacman --sync --refresh
pacman --sync --noconfirm archlinux-keyring

# Install CachyOS keyring and mirrorlist packages and add CachyOS v3 repositories
if [[ "${USE_CACHYOS}" -eq 1 ]]; then
  install_cachyos_v3
  add_cachyos_v3 /etc/pacman.conf
  pacman --sync --noconfirm --needed rate-mirrors
  if [[ -n "${COUNTRY}" ]]; then
    country_args=(--entry-country="${COUNTRY}")
  else
    country_args=()
  fi
  rate-mirrors --save=/etc/pacman.d/cachyos-v3-mirrorlist --max-jumps=0 \
    "${country_args[@]}" --allow-root cachyos \
    || echo 'Warning: CachyOS mirror ranking failed.' >&2
fi

# Refresh repositories and upgrade packages
pacman --sync --refresh --sysupgrade --noconfirm

# Parallel compilation
threads="$(nproc)"
sed --in-place "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j${threads}\"/g" /etc/makepkg.conf

# Multiple cores on compression
sed --in-place "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c --threads=${threads} -z -)/g" /etc/makepkg.conf

# Install essential packages
read_pkglist /renge/pkgs/install-pacman-pkglist.txt \
  | sort --unique \
  | pacman --sync --noconfirm --needed -

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

#######################################
# Graphical user interface
#######################################
 
# Uncomment if mangowm is NOT in AUR
pacman --sync --noconfirm --needed mangowm
 
# Uncomment if mangowm is in AUR
# install_aur scenefx0.5
# install_aur mangowm-git
 
# User directories
runuser --login "${USERNAME}" --command xdg-user-dirs-update

#######################################
# Multimedia
#######################################

# Audio players
runuser --user="${USERNAME}" -- mkdir --parents \
/home/"${USERNAME}"/.config/mpd/playlists \
/home/"${USERNAME}"/.local/state/mpd

# Enable audio player daemons
systemctl --global enable mpd
systemctl --global enable spotifyd.service

# Sound system
#   amixer sset Master unmute; amixer sset Speaker unmute
#   amixer sset Headphone unmute

#######################################
# Networking
#######################################
 
# Web browser
install_aur zen-browser-bin

#######################################
# Input devices
#######################################
 
# mozc-ut (fcitx5-mozc-ut dependency)
runuser --login "${USERNAME}" --command 'rm --recursive --force "$HOME/.cache/bazel"'
install_aur mozc-ut
 
# Input method
runuser --login "${USERNAME}" --command 'rm --recursive --force "$HOME/.cache/bazel"'
install_aur fcitx5-mozc-ut

#######################################
# Optimization
#######################################
 
# Solid state drives
systemctl enable fstrim.timer

#######################################
# System services
#######################################
 
# Apply config files
mkdir --parents /home/"${USERNAME}"/.config
cp --recursive /renge/.config/. /home/"${USERNAME}"/.config/
chown --recursive "${USERNAME}":"${USERNAME}" /home/"${USERNAME}"/.config
mkdir --parents /home/"${USERNAME}"/Pictures/Wallpapers
cp --recursive /renge/pictures/wallpapers/. /home/"${USERNAME}"/Pictures/Wallpapers
chown --recursive "${USERNAME}":"${USERNAME}" /home/"${USERNAME}"/Pictures

#######################################
# Gaming
#######################################
 
install_aur proton-cachyos-slr
install_aur wine-cachyos-opt
install_aur heroic-games-launcher-bin

#######################################
# Cleanup
#######################################
 
# Remove renge folder
rm --recursive --force /renge
CHROOT_EOF
} > /mnt/chroot-install.sh
chmod 0700 /mnt/chroot-install.sh

# Change root into new system
arch-chroot -S /mnt /usr/bin/env \
  USERNAME="${USERNAME}" \
  NAME_OF_MACHINE="${NAME_OF_MACHINE}" \
  TIME_ZONE="${time_zone}" \
  KEYMAP="${KEYMAP}" \
  COUNTRY="${country}" \
  BOOT_DISK="${boot_disk}" \
  USE_CACHYOS="${use_cachyos}" \
  /bin/bash /chroot-install.sh
 
rm --force /mnt/chroot-install.sh

# Set root and user passwords
printf '%s:%s\n' root "${ROOT_PASSWORD}" "${USERNAME}" "${USER_PASSWORD}" \
  | arch-chroot /mnt chpasswd

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
  sec=$((sec - 1))
done
printf "\r\e[K%s\n" "Restarting in 1 second"
sleep 1
reboot
