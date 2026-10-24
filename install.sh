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
cd "$(dirname "${BASH_SOURCE[0]}")/.."

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
    "${conf}"

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
  block+='[cachyos-extra-v3]\nInclude = /etc/pacman.d/cachyos-v3-mirrorlist\n'

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
for file in ./renge/.config/qt5ct/qt5ct.conf \
            ./renge/.config/qt6ct/qt6ct.conf \
            ./renge/pkgs/install-pacman-pkglist.txt \
            ./renge/pkgs/install-pacstrap-pkglist.txt \
            ./renge/etc/greetd/config.toml \
            ./renge/etc/greetd/greeter/shell.qml \
            ./renge/etc/greetd/greeter/Config.qml \
            ./renge/etc/greetd/greeter/wallpaper.png \
            ./renge/etc/dconf/db/local.d/00-appearance \
            ./renge/etc/dconf/profile/user \
            ./renge/usr/share/themes/Kanagawa-Dragon/index.theme; do
  if [[ ! -f "${file}" ]]; then
    printf '%s\n' "Missing file: ${file}" >&2
    exit 1
  fi
done

# Check secure boot
secure_boot_var=/sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c
if [[ -r "${secure_boot_var}" ]]; then
  secure_boot="$(od --address-radix=n --format=u1 --skip-bytes=4 \
    --read-bytes=1 "${secure_boot_var}" | tr -d '[:space:]')"
  if [[ "${secure_boot}" == '1' ]]; then
    printf '%s\n' "System is booted with Secure Boot enabled. Refer to your motherboard's manual." >&2
    exit 1
  fi
fi

# Check boot mode
if [[ ! -f /sys/firmware/efi/fw_platform_size ]]; then
  printf '%s\n' "System is booted in BIOS (or CSM) mode. Refer to your motherboard's manual." >&2
  exit 1
fi

# Check IOMMU
if ! check_vm && ! compgen -G '/sys/kernel/iommu_groups/*' > /dev/null; then
  printf '%s\n' "System is booted with IOMMU disabled. Refer to your motherboard's manual." >&2
  exit 1
fi

# Check NX mode
if ! grep --quiet --word-regexp nx /proc/cpuinfo; then
  printf '%s\n' "System is booted with NX mode disabled. Refer to your motherboard's manual." >&2
  exit 1
fi

# Check SVM mode
if ! check_vm && ! grep --quiet --word-regexp svm /proc/cpuinfo; then
  printf '%s\n' "System is booted with SVM mode disabled. Refer to your motherboard's manual." >&2
  exit 1
fi

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
  NAME_OF_MACHINE=${name_of_machine,,}
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

# Update the system clock
timedatectl set-ntp true

#######################################
# Prepare the disks
#######################################

# Install prerequisite packages
pacman --sync --noconfirm gptfdisk btrfs-progs

# Unmount all disks
umount --all-targets --recursive /mnt || true

# Destroy old signatures, GPT and MBR data structure on all disks
for disk in "${disks[@]}"; do
  wipefs --all --force "${disk}"
  sgdisk --zap-all "${disk}"
done

#######################################
# Partition the disks
#######################################

# Boot Disk, Partition 1: UEFI Boot
sgdisk --new=1::+4096MiB --typecode=1:ef00 --change-name=1:'boot' "$boot_disk"

# Root Disk, Partition 2: Root
sgdisk --new=2::-0 --typecode=2:8300 --change-name=2:'root' "$root_disk"

# Var Disk, Partition 1: Var
sgdisk --new=1::+12G --typecode=1:8300 --change-name=1:'var' "$var_disk"

# Home Disk, Partition 2: Home
sgdisk --new=2::-0 --typecode=2:8300 --change-name=2:'home' "$home_disk"

# Data Disk, Partition 1: Data
sgdisk --new=1::-0 --typecode=1:8300 --change-name=1:'data' "$data_disk"

# Confirm the new partitions
partprobe "${disks[@]}"
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
video_arg=''
if check_vm; then
  video_arg=' video=Virtual-1:1920x1080'
fi
root_uuid="$(blkid -s UUID -o value "$root_part")"
cmdline="root=UUID=${root_uuid} rootflags=subvol=@,noatime,compress=zstd,ssd,commit=120 rw rootfstype=btrfs${video_arg}"
cmdline_acs="${cmdline} video=efifb:off pcie_acs_override=downstream,multifunction"
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
  cmdline: ${cmdline_acs}
  module_path: boot():/amd-ucode.img
  module_path: boot():/initramfs-${kernel}.img
  //linux-lts
  protocol: linux
  path: boot():/vmlinuz-linux-lts
  cmdline: ${cmdline}
  module_path: boot():/amd-ucode.img
  module_path: boot():/initramfs-linux-lts.img
/Memtest86+
  protocol: efi
  path: boot():/memtest86+/memtest86x64.efi
EOF

# Copy config files
cp --recursive ./renge /mnt

#######################################
# Configure the system
#######################################

# Generate fstab file
genfstab -U /mnt >> /mnt/etc/fstab

# Show partition in file manager
awk -v OFS='\t' '$1 !~ /^#/ && ($2 == "/home" || $2 == "/data") { $4 = $4 ",x-gvfs-show" } { print }' \
  /mnt/etc/fstab > /mnt/etc/fstab.new
cat /mnt/etc/fstab.new > /mnt/etc/fstab
rm --force /mnt/etc/fstab.new

# Create chroot script
{
  declare -f check_vm configure_pacman add_cachyos_v3 install_cachyos_v3 read_pkglist
  cat << 'CHROOT_EOF'

# Errors will cause the script to immediately fail
set -euo pipefail

# Build and install AUR helper
install_helper() {
  local pkg=$1
  runuser --login "${USERNAME}" --command \
    "git clone https://aur.archlinux.org/${pkg}.git \"\$HOME/${pkg}\" \
    && cd \"\$HOME/${pkg}\" \
    && makepkg --syncdeps --install --noconfirm"
}

# Install AUR package
install_aur() {
  local pkg=$1
  runuser --login "${USERNAME}" --command \
    "paru --sync --needed --noconfirm --skipreview ${pkg}"
}

# Optional build and install AUR package
failed_aur=()
install_aur_optional() {
  if ! install_aur "$1"; then
    echo "Warning: AUR build failed: $1" >&2
    failed_aur+=("$1")
  fi
}

# Hide unnecessary desktop entry
hide_desktop_entry() {
  local app=$1
  local src="/usr/share/applications/${app}.desktop"
  local dst="/home/${USERNAME}/.local/share/applications/${app}.desktop"
  local value
 
  if [[ ! -f "${src}" ]]; then
    echo "Warning: desktop entry not found: ${app}" >&2
    return 1
  fi
 
  cp "${src}" "${dst}"
  sed --in-place \
    --expression='/^NoDisplay=/d' \
    --expression='/^\[Desktop Entry\]/a NoDisplay=true' \
    "${dst}"
 
  value="$(awk -F= '/^\[/ {s = $0}
                    s == "[Desktop Entry]" && $1 == "NoDisplay" {v = $2}
                    END {print v}' "${dst}")"
  [[ "${value}" == 'true' ]]
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
pacman --sync --refresh --needed --noconfirm archlinux-keyring 
pacman --sync --sysupgrade --noconfirm

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

# Install AUR helper
install_helper paru

# Deploy boot loader
mkdir --parents /boot/EFI/arch-limine
cp /usr/share/limine/BOOTX64.EFI /boot/EFI/arch-limine/

# pacman hook
mkdir --parents /etc/pacman.d/hooks
cat << 'HOOK_EOF' > /etc/pacman.d/hooks/99-limine.hook
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = limine
 
[Action]
Description = Deploying Limine after upgrade...
When = PostTransaction
Exec = /usr/bin/cp /usr/share/limine/BOOTX64.EFI /boot/EFI/arch-limine/
HOOK_EOF

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

# Display manager
mkdir --parents /etc/greetd
cp --recursive /renge/etc/greetd/. /etc/greetd/
sed --in-place \
  "s/\(property string username: \)\"[^\"]*\"/\1\"${USERNAME}\"/" \
  /etc/greetd/greeter/Config.qml
chown --recursive greeter:greeter /etc/greetd
systemctl enable greetd.service

# User directories
runuser --login "${USERNAME}" --command xdg-user-dirs-update

# File managers
runuser --login "${USERNAME}" --command 'xdg-mime default thunar.desktop inode/directory'
sed --in-place "s/AutoMount=true/AutoMount=false/g" /usr/share/gvfs/mounts/network.mount

#######################################
# Multimedia
#######################################

# Audio players
runuser --user="${USERNAME}" -- mkdir --parents \
/home/"${USERNAME}"/.config/mpd/playlists \
/home/"${USERNAME}"/.local/state/mpd

# Audio Tag Editor
install_aur puddletag

# Screencast
install_aur obs-vkcapture

# Enable audio player daemons
systemctl --global enable mpd.service
systemctl --global enable mpd-mpris.service
systemctl --global enable spotifyd.service

#######################################
# Networking
#######################################

# Web browser
install_aur zen-browser-bin

#######################################
# Input devices
#######################################

# Input method
install_aur fcitx5-mozc-ut

#######################################
# Optimization
#######################################

# Overclocking
systemctl enable lactd.service

# Solid state drives
systemctl enable fstrim.timer

#######################################
# System services
#######################################

# Apply config files
mkdir --parents /home/"${USERNAME}"/.config
cp --recursive /renge/.config/. /home/"${USERNAME}"/.config/
sed --in-place "s|__USERNAME__|${USERNAME}|" \
  /home/"${USERNAME}"/.config/qt5ct/qt5ct.conf \
  /home/"${USERNAME}"/.config/qt6ct/qt6ct.conf
chown --recursive "${USERNAME}":"${USERNAME}" /home/"${USERNAME}"/.config
mkdir --parents /home/"${USERNAME}"/.local
cp --recursive /renge/.local/. /home/"${USERNAME}"/.local/
mkdir --parents /home/"${USERNAME}"/Pictures/Screenshots
mkdir --parents /home/"${USERNAME}"/Pictures/Logo
cp --recursive /renge/pictures/logo/. /home/"${USERNAME}"/Pictures/Logo
mkdir --parents /home/"${USERNAME}"/Pictures/Wallpapers
cp --recursive /renge/pictures/wallpapers/. /home/"${USERNAME}"/Pictures/Wallpapers
chown --recursive "${USERNAME}":"${USERNAME}" /home/"${USERNAME}"/Pictures
mkdir --parents /home/"${USERNAME}"/to-do
cp --recursive /renge/to-do/. /home/"${USERNAME}"/to-do/
chown --recursive "${USERNAME}":"${USERNAME}" /home/"${USERNAME}"/to-do
mkdir --parents /etc/dconf
cp --recursive /renge/etc/dconf/. /etc/dconf/
dconf update

# Docker
systemctl enable docker.socket
usermod --append --groups docker "${USERNAME}"
mkdir --parents /home/"${USERNAME}"/searxng/core-config/
curl --fail --silent --show-error --location --output-dir /home/"${USERNAME}"/searxng \
  --remote-name https://raw.githubusercontent.com/searxng/searxng/master/container/docker-compose.yml \
  --remote-name https://raw.githubusercontent.com/searxng/searxng/master/container/.env.example
cp --no-clobber "/home/"${USERNAME}"/searxng/.env.example" "/home/"${USERNAME}"/searxng/.env"
chown --recursive "${USERNAME}":"${USERNAME}" /home/"${USERNAME}"/searxng

# OpenRGB
systemctl enable openrgb.service

# Ventoy
install_aur ventoy-bin

# Vesktop
install_aur vesktop-bin

#######################################
# Appearance
#######################################

# Cursor theme
install_aur bibata-cursor-theme-bin

# GTK and Qt themes
install_aur gtk-engine-murrine
mkdir --parents /usr/share/themes
cp --recursive /renge/usr/share/themes/. /usr/share/themes/
install_aur papirus-folders-git
papirus-folders -C paleorange --theme Papirus-Dark

# Neovim
npm install --global neovim
cat << 'ENV_EOF' >> /etc/environment
VISUAL=nvim
EDITOR=nvim
MANPAGER="nvim +Man!"
ENV_EOF

#######################################
# Gaming
#######################################

install_aur proton-cachyos-slr
install_aur wine-cachyos-opt
install_aur heroic-games-launcher-bin

#######################################
# Virtualization
#######################################

# Configuration of libvirt
install_aur bridge-utils
sed --in-place 's/#unix_sock_group = \"libvirt\"/unix_sock_group = \"libvirt\"/g' /etc/libvirt/libvirtd.conf
sed --in-place 's/#unix_sock_rw_perms = \"0770\"/unix_sock_rw_perms = \"0770\"/g' /etc/libvirt/libvirtd.conf
sed --in-place 's/#log_filters=\"1:qemu 1:libvirt 4:object 4:json 4:event 1:util\"/log_filters=\"3:qemu 1:libvirt\"/g' /etc/libvirt/libvirtd.conf
sed --in-place 's|#log_outputs=\"3:syslog:libvirtd\"|log_outputs=\"2:file:/var/log/libvirt/libvirtd.log\"|g' /etc/libvirt/libvirtd.conf
usermod --append --groups kvm,libvirt "${USERNAME}"
sed --in-place "s/#user = \"libvirt-qemu\"/user = \"${USERNAME}\"/g" /etc/libvirt/qemu.conf
sed --in-place "s/#group = \"libvirt-qemu\"/group = \"${USERNAME}\"/g" /etc/libvirt/qemu.conf
systemctl enable libvirtd
mkdir /home/"${USERNAME}"/Virtualization
chown --recursive "${USERNAME}":"${USERNAME}" /home/"${USERNAME}"/Virtualization

#######################################
# Cleanup
#######################################

# Hide desktop entries
for app in avahi-discover bssh bvnc cmake-gui fcitx5-configtool footclient foot-server kbd-layout-viewer5 lstopo org.fcitx.fcitx5-migrator org.gnome.Yelp org.xfce.Catfish protontricks qt5ct qt6ct qv4l2 qvidcap remote-viewer thunar-settings ventoy winetricks xfce4-about; do
  if hide_desktop_entry "${app}"; then
    echo "Hidden: ${app}"
  else
    echo "Warning: could not hide: ${app}" >&2
  fi
done
chown --recursive "${USERNAME}":"${USERNAME}" /home/"${USERNAME}"/.local

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
