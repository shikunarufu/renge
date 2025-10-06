#!/bin/bash
#
# Shiku's Post Arch Linux Installation Script

# This script automates the post-installation process of Arch Linux.

# This script assumes you have already booted
# and logged in into the new system with the user account.

# This script assumes a working internet connection is available.

# Uncomment the line below to show command outputs.
# set -x

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
  echo "Failed to connect to the internet"
  rm --force --recursive /home/"${username}"/renge
  exit
fi

# Allow members of group wheel sudo access without a password
printf "%s\n%s" "${user_passwd}" "${user_passwd}" | sudo --stdin sed --in-place 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers

#######################################
# Installation
#######################################

# Yay
if ! sudo pacman -S --noconfirm --needed git base-devel; then
  echo "Failed to install Yay dependencies"
  rm --force --recursive /home/"${username}"/renge
  exit
fi
if ! git clone https://aur.archlinux.org/yay.git; then
  if ! git clone --branch yay --single-branch https://github.com/archlinux/aur.git yay; then
    echo "Failed to clone Yay repository"
    rm --force --recursive /home/"${username}"/yay
    rm --force --recursive /home/"${username}"/renge
    exit
  fi
fi
cd yay || exit
makepkg -si --noconfirm
yay --yay --gendb
yay -Syu --devel --answerupgrade None --noconfirm
yay --yay --devel --save

# Hyprland
if ! yay -S --answerclean All --answerdiff None --noconfirm ninja gcc cmake meson libxcb xcb-proto xcb-util xcb-util-keysyms libxfixes libx11 libxcomposite libxrender libxcursor pixman wayland-protocols cairo pango libxkbcommon xcb-util-wm xorg-xwayland libinput libliftoff libdisplay-info cpio tomlplusplus hyprlang-git hyprcursor-git hyprwayland-scanner-git xcb-util-errors hyprutils-git glaze hyprgraphics-git aquamarine-git re2 hyprland-qtutils; then
  make clean
  make && sudo make install
  if [ $? -eq 0 ]; then
    echo "Installed Hyprland dependencies"
  else
    echo "Failed to install Hyprland dependencies"
    rm --force --recursive /home/"${username}"/yay
    rm --force --recursive /home/"${username}"/renge
    exit
  fi
  cd /home/"${username}"
fi
if ! git clone --recursive https://github.com/hyprwm/Hyprland; then
  echo "Failed to clone Hyprland repository"
  rm --force --recursive /home/"${username}"/yay
  rm --force --recursive /home/"${username}"/renge
  exit
fi
cd Hyprland || exit
make all && sudo make install
cp --recursive /home/"${username}"/renge/hypr /home/"${username}"/.config

# Pacman Packages
if ! curl --silent --location https://raw.githubusercontent.com/shikunarufu/renge/refs/heads/main/pkgs/post-pacman-pkglist.txt >> post-pacman-pkglist.txt; then
  echo "Failed to retrieve package list"
  rm --force --recursive /home/"${username}"/yay
  rm --force --recursive /home/"${username}"/renge
  exit
fi
grep --extended-regexp --only-matching '^[^(#|[:space:])]*' post-pacman-pkglist.txt | sort --output=post-pacman-pkglist.txt --unique
if ! sudo pacman -S --noconfirm --needed - < post-pacman-pkglist.txt; then
  echo "Failed to install packages"
  rm --force --recursive /home/"${username}"/yay
  rm --force --recursive /home/"${username}"/renge
  exit
fi
rm post-pacman-pkglist.txt

# Yay Packages
if ! curl --silent --location https://raw.githubusercontent.com/shikunarufu/renge/refs/heads/main/pkgs/post-yay-pkglist.txt >> post-yay-pkglist.txt; then
  echo "Failed to retrieve (AUR) package list"
  rm --force --recursive /home/"${username}"/yay
  rm --force --recursive /home/"${username}"/renge
  exit
fi
grep --extended-regexp --only-matching '^[^(#|[:space:])]*' post-yay-pkglist.txt | sort --output=post-yay-pkglist.txt --unique
if ! yay -S --answerclean All --answerdiff None --noconfirm - < post-yay-pkglist.txt; then
  echo "Failed to install (AUR) packages"
  rm --force --recursive /home/"${username}"/yay
  rm --force --recursive /home/"${username}"/renge
  exit
fi
rm post-yay-pkglist.txt

# Flatpak Packages
if ! curl --silent --location https://raw.githubusercontent.com/shikunarufu/renge/refs/heads/main/pkgs/post-flatpak-pkglist.txt >> post-flatpak-pkglist.txt; then
  echo "Failed to retrieve (Flatpak) package list"
  rm --force --recursive /home/"${username}"/yay
  rm --force --recursive /home/"${username}"/renge
  exit
fi
grep --extended-regexp --only-matching '^[^(#|[:space:])]*' post-flatpak-pkglist.txt | sort --output=post-flatpak-pkglist.txt --unique
fp_pkg="post-flatpak-pkglist.txt"
while IFS= read -r app_id; do
  if ! flatpak install --assumeyes --noninteractive flathub "$app_id"; then
    echo "Failed to install (Flatpak) packages"
    rm --force --recursive /home/"${username}"/yay
    rm --force --recursive /home/"${username}"/renge
    exit
  fi
done < "$fp_pkg"
rm post-flatpak-pkglist.txt

# Foot
cp --recursive /home/"${username}"/renge/foot /home/"${username}"/.config

# Fish
cp --recursive /home/"${username}"/renge/fish /home/"${username}"/.config

# Starship
cp --recursive /home/"${username}"/renge/starship/starship.toml /home/"${username}"/.config

# Greetd
sudo sed --in-place 's|command = "agreety --cmd /bin/sh"|command = "tuigreet --cmd Hyprland --remember"|g' /etc/greetd/config.toml
sudo systemctl enable greetd.service

# Mako
cp --recursive /home/"${username}"/renge/mako /home/"${username}"/.config

# Waybar
cp --recursive /home/"${username}"/renge/waybar /home/"${username}"/.config

# SWWW
mkdir /home/"${username}"/Pictures/Wallpapers
cp /home/"${username}"/renge/pictures/wallpapers/desktop.png /home/"${username}"/Pictures/Wallpapers
# swww img /home/"${username}"/Pictures/Wallpapers/desktop.png

# Rofi
cp --recursive /home/"${username}"/renge/rofi /home/"${username}"/.config

# Hyprshot
mkdir /home/"${username}"/Pictures/Screenshots

# Fastfetch
mkdir /home/"${username}"/Pictures/Logo
cp /home/"${username}"/renge/pictures/logo/shiku.sixel /home/"${username}"/Pictures/Logo
cp --recursive /home/"${username}"/renge/fastfetch /home/"${username}"/.config

# SpotX
bash <(curl -sSL https://spotx-official.github.io/run.sh)

# Linux GPU Control Application
if ! sudo systemctl enable --now lactd; then
  echo "Failed to enable lactd"
  rm --force --recursive /home/"${username}"/yay
  rm --force --recursive /home/"${username}"/renge
  exit
fi

#######################################
# Virtualization
#######################################

# Installation of virtualization packages
yes y | sudo pacman -S --needed virt-manager qemu-full vde2 ebtables iptables-nft nftables dnsmasq bridge-utils ovmf

# Configuration of libvirt
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
mkdir /home/"${username}"/Virtualization

#######################################
# Post-Installation
#######################################

# Clean
yay -Scc --noconfirm

# Allow members of group wheel sudo access with a password
sudo sed --in-place 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers

# Launch Hyprland
Hyprland
