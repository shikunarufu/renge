#!/bin/bash

# Shiku's Post Arch Linux Installation Script

# This script automates the post-installation process of Arch Linux.

# This script assumes you have already booted
# and logged in into the new system with the user account.

# This script assumes a working internet connection is available.

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

#######################################
# Preparation
#######################################

# Configuration
username="Shiku"
user_passwd="narufu"

# Clear the terminal screen
clear

# Connect to the internet
if ! ping -c 1 archlinux.org; then
  printf "%s\n" "Failed to connect to the internet"
  rm --force --recursive /home/"${username}"/renge
  exit
fi

# Allow members of group wheel sudo access without a password
printf "%s\n%s" "${user_passwd}" "${user_passwd}" | sudo --stdin sed --in-place 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers

# Create default directories
xdg-user-dirs-update

#######################################
# Installation
#######################################

# Yay
if ! sudo pacman -S --noconfirm --needed git base-devel; then
  printf "%s\n" "Failed to install Yay dependencies"
  rm --force --recursive /home/"${username}"/renge
  exit
fi
if ! git clone https://aur.archlinux.org/yay.git; then
  if ! git clone --branch yay --single-branch https://github.com/archlinux/aur.git yay; then
    printf "%s\n" "Failed to clone Yay repository"
    rm --force --recursive /home/"${username}"/renge
    rm --force --recursive /home/"${username}"/yay
    exit
  fi
fi
cd yay || exit
makepkg -si --noconfirm
yay --yay --gendb
yay -Syu --devel --answerupgrade None --noconfirm
yay --yay --devel --save

# Hyprland
grep --extended-regexp --only-matching '^[^(#|[:space:])]*' /home/"${username}"/renge/pkgs/hyprland-pkglist.txt | sort --output=/home/"${username}"/renge/pkgs/hyprland-pkglist.txt --unique
if ! yay -S --answerclean All --answerdiff None --noconfirm - < /home/"${username}"/renge/pkgs/hyprland-pkglist.txt; then
  hyprland_pkglist="hyprland-pkglist.txt"
  mkdir --parents /home/"${username}"/AUR
  cd AUR || exit
  while IFS= read -r hyprland_pkgs; do
    if ! git clone --branch "${hyprland_pkgs}" --single-branch https://github.com/archlinux/aur.git "${hyprland_pkgs}"; then
      break
      printf "%s\n" "Failed to install (Hyprland) packages"
      rm --force --recursive /home/"${username}"/renge
      rm --force --recursive /home/"${username}"/yay
      rm --force --recursive /home/"${username}"/AUR
      exit
    fi
    cd "$hyprland_pkgs"
    makepkg -si --noconfirm
  done < /home/"${username}"/renge/pkgs/"${hyprland_pkglist}"
fi
if ! git clone --recursive https://github.com/hyprwm/Hyprland; then
  printf "%s\n" "Failed to clone Hyprland repository"
  rm --force --recursive /home/"${username}"/renge
  rm --force --recursive /home/"${username}"/yay
  rm --force --recursive /home/"${username}"/AUR
  exit
fi
cd Hyprland || exit
make all && sudo make install
cp --recursive /home/"${username}"/renge/hypr /home/"${username}"/.config

# Pacman Packages
grep --extended-regexp --only-matching '^[^(#|[:space:])]*' /home/"${username}"/renge/pkgs/post-pacman-pkglist.txt | sort --output=/home/"${username}"/renge/pkgs/post-pacman-pkglist.txt --unique
if ! sudo pacman -S --noconfirm --needed - < /home/"${username}"/renge/pkgs/post-pacman-pkglist.txt; then
  printf "%s\n" "Failed to install packages"
  rm --force --recursive /home/"${username}"/renge
  rm --force --recursive /home/"${username}"/yay
  rm --force --recursive /home/"${username}"/AUR
  exit
fi

# Yay Packages
grep --extended-regexp --only-matching '^[^(#|[:space:])]*' /home/"${username}"/renge/pkgs/post-yay-pkglist.txt | sort --output=/home/"${username}"/renge/pkgs/post-yay-pkglist.txt --unique
if ! yay -S --answerclean All --answerdiff None --noconfirm - < /home/"${username}"/renge/pkgs/post-yay-pkglist.txt; then
  printf "%s\n" "Failed to install (AUR) packages"
  rm --force --recursive /home/"${username}"/renge
  rm --force --recursive /home/"${username}"/yay
  rm --force --recursive /home/"${username}"/AUR
  exit
fi

# Bin
mkdir --parents /home/"${username}"/.local/share/renge
cp --recursive /home/"${username}"/renge/bin /home/"${username}"/.local/share/renge

# Foot
cp --recursive /home/"${username}"/renge/foot /home/"${username}"/.config

# Fish
cp --recursive /home/"${username}"/renge/fish /home/"${username}"/.config

# Starship
cp --recursive /home/"${username}"/renge/starship/starship.toml /home/"${username}"/.config

# Universal Wayland Session Manager
cp --recursive /home/"${username}"/renge/uwsm /home/"${username}"/.config
cp --recursive /home/"${username}"/renge/environment.d /home/"${username}"/.config

# Greetd
sudo sed --in-place 's|command = "agreety --cmd /bin/sh"|command = "tuigreet exec uwsm start hyprland.desktop --remember"|g' /etc/greetd/config.toml
sudo systemctl enable greetd.service

# Mako
cp --recursive /home/"${username}"/renge/mako /home/"${username}"/.config

# Waybar
cp --recursive /home/"${username}"/renge/waybar /home/"${username}"/.config

# SWWW
mkdir --parents /home/"${username}"/Pictures/Wallpapers
cp /home/"${username}"/renge/pictures/wallpapers/desktop.png /home/"${username}"/Pictures/Wallpapers
# swww img /home/"${username}"/Pictures/Wallpapers/desktop.png

# Rofi
cp --recursive /home/"${username}"/renge/rofi /home/"${username}"/.config

# Dolphin
xdg-mime default org.kde.dolphin.desktop inode/directory

# SwayOSD
cp --recursive /home/"${username}"/renge/swayosd /home/"${username}"/.config

# Imv
cp --recursive /home/"${username}"/renge/imv /home/"${username}"/.config

# Hyprshot
mkdir --parents /home/"${username}"/Pictures/Screenshots

# BTOP++
cp --recursive /home/"${username}"/renge/btop /home/"${username}"/.config

# Fastfetch
mkdir --parents /home/"${username}"/Pictures/Logo
cp /home/"${username}"/renge/pictures/logo/shiku.sixel /home/"${username}"/Pictures/Logo
cp --recursive /home/"${username}"/renge/fastfetch /home/"${username}"/.config

# SpotX
bash <(curl -sSL https://spotx-official.github.io/run.sh)

# Steam
printf "%s\n" "vm.max_map_count = 2147483642" | sudo tee --append /etc/sysctl.d/80-gamecompatibility.conf

# Fcitx5
cp --recursive /home/"${username}"/renge/fcitx5 /home/"${username}"/.config

# Linux GPU Control Application
if ! sudo systemctl enable --now lactd; then
  printf "%s\n" "Failed to enable lactd"
  rm --force --recursive /home/"${username}"/renge
  rm --force --recursive /home/"${username}"/yay
  rm --force --recursive /home/"${username}"/AUR
  exit
fi

#######################################
# Virtualization
#######################################

# Verify the boot mode
# boot="$(cat /sys/firmware/efi/fw_platform_size)"
# if [[ "${boot}" == "64" ]]; then
#   printf "%s\n" "System is booted in UEFI mode and has a 64-bit x64 UEFI"
# elif [[ "${boot}" == "32" ]]; then
#   printf "%s\n" "System is booted in UEFI mode and has a 32-bit IA32 UEFI"
# else
#   printf "%s\n" "System may be booted in BIOS (or CSM) mode"
#   printf "%s\n" "Refer to your motherboard's manual"
#   exit
# fi

# Verify IOMMU
# iommu="$(sudo dmesg | grep --extended-regexp 'IOMMU' | grep --extended-regexp --max-count 1 'IOMMU')"
# if [[ "${iommu}" == "[    0.000000] DMAR: IOMMU enabled" ]]; then
#   printf "%s\n" "System is booted with IOMMU enabled"
# elif [[ "${iommu}" == "[    0.000000] Warning: PCIe ACS overrides enabled; This may allow non-IOMMU protected peer-to-peer DMA" ]]; then
#   printf "%s\n" "System is booted with IOMMU enabled and has ACS override patch"
# else
#   printf "%s\n" "System may be booted with IOMMU disabled"
#   printf "%s\n" "Refer to your BIOS's manual"
#   exit
# fi

# Verify NX mode
# nx="$(sudo dmesg | grep --extended-regexp 'Execute Disable')"
# if [[ "${nx}" == "[    0.000000] NX (Execute Disable) protection: active" ]]; then
#   printf "%s\n" "System is booted with NX mode enabled"
# else
#   printf "%s\n" "System may be booted with NX mode disabled"
#   printf "%s\n" "Refer to your BIOS's manual"
#   exit
# fi

# Verify SVM mode
# vendor="$(lscpu | grep --extended-regexp --only-matching 'AuthenticAMD')"
# if [[ "${vendor}" == "AuthenticAMD" ]]; then
#   svm="$(lscpu | grep --extended-regexp --word-regexp --only-matching 'svm')"
#   if [[ "${svm}" == "svm" ]]; then
#     printf "%s\n" "System is booted with SVM mode enabled"
#   else
#     printf "%s\n" "System may be booted with SVM mode disabled"
#     printf "%s\n" "Refer to your BIOS's manual"
#     exit
#   fi
# fi

# Install virtualization packages
yes y | sudo pacman -S --needed virt-manager qemu-full vde2 ebtables iptables-nft nftables dnsmasq bridge-utils ovmf || [ $? -eq 141 ]

# Configure libvirt
sudo sed --in-place 's/#unix_sock_group = \"libvirt\"/unix_sock_group = \"libvirt\"/g' /etc/libvirt/libvirtd.conf
sudo sed --in-place 's/#unix_sock_rw_perms = \"0770\"/unix_sock_rw_perms = \"0770\"/g' /etc/libvirt/libvirtd.conf
sudo sed --in-place 's/#log_filters=\"1:qemu 1:libvirt 4:object 4:json 4:event 1:util\"/log_filters=\"3:qemu 1:libvirt\"/g' /etc/libvirt/libvirtd.conf
sudo sed --in-place 's|#log_outputs=\"3:syslog:libvirtd\"|log_outputs=\"2:file:/var/log/libvirt/libvirtd.log\"|g' /etc/libvirt/libvirtd.conf
sudo usermod --append --groups kvm,libvirt "${username}"
sudo systemctl enable libvirtd
sudo systemctl start libvirtd
sudo sed --in-place "s/#user = \"libvirt-qemu\"/user = \"$username\"/g" /etc/libvirt/qemu.conf
sudo sed --in-place "s/#group = \"libvirt-qemu\"/group = \"$username\"/g" /etc/libvirt/qemu.conf
sudo systemctl restart libvirtd
sudo virsh net-autostart default
mkdir --parents /home/"${username}"/Virtualization

#######################################
# Post-Installation
#######################################

# Clean
yay -Scc --noconfirm

# Allow members of group wheel sudo access with a password
sudo sed --in-place 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers

# Reboot
sec=15
while [[ ${sec} -gt 1 ]]; do
  printf "\033[2K"
  printf "\033[9C%s\r" "Restarting in $sec seconds"
  sleep 1
  ((sec--))
done
printf "\033[2K"
printf "\033[9C%s\r" "Restarting in 1 second"
sleep 1
reboot
